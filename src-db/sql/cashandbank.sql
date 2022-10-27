/* CashAndBank.sql */
CREATE OR REPLACE FUNCTION c_cash_post(p_pinstance_id character varying) RETURNS void
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
  *************************************************************************
  * $Id: C_Cash_Post.sql,v 1.10 2003/03/17 20:32:25 jjanke Exp $
  ***
  * Title: Post Cash Book Entry
  * Description:
  * - Create Payment entry for Transfer: DELETED!!! May do it from Settlement
  *  - Create Allocation for Invoices (trigger updates SO_CreditUsed):
  *  - Update Balance and De-Activate
  ************************************************************************/
  --  Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC;
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Record_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  v_User VARCHAR(32); --OBTG:VARCHAR2--
  v_C_Debt_Payment_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_C_Order_ID VARCHAR(32); --OBTG:VARCHAR2--
  --Added by P.SAROBE
        v_documentno_Settlement VARCHAR(40); --OBTG:VARCHAR2--
        v_dateSettlement TIMESTAMP;
        v_Cancel_Processed VARCHAR(60);
        v_nameBankstatement VARCHAR (60); --OBTG:VARCHAR2--
        v_dateBankstatement TIMESTAMP;
        v_nameCash VARCHAR (60); --OBTG:VARCHAR2--
        v_dateCash TIMESTAMP;
        v_Bankstatementline_ID VARCHAR(32); --OBTG:VARCHAR2--
        v_CashLine_ID VARCHAR(32); --OBTG:VARCHAR2--
        v_Settlement_Cancel_ID VARCHAR(32); --OBTG:VARCHAR2--
        v_ispaid CHAR(1);
  v_is_included NUMERIC:=0;
  v_available_period NUMERIC:=0;
  v_is_ready AD_Org.IsReady%TYPE;
  v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
  v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
  v_org_bule_id AD_Org.AD_Org_ID%TYPE;
        --Finish added by P.Sarobe
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    Cur_CashlineDebtpayment RECORD;
    --  Parameter Variables
    v_Processed VARCHAR(60);
    v_Posted VARCHAR(60);
    v_count NUMERIC;
    v_SettlementDocType_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_settlementID VARCHAR(32) ; --OBTG:varchar2--
    v_DocumentNo VARCHAR(40) ;
    v_line C_CASHLINE.LINE%TYPE;
    -- CashBook
    v_CB_Currency_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_CB_Date TIMESTAMP;
    v_AD_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AD_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_C_Settlement_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_C_CashBook_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    FINISH_PROCESS BOOLEAN:=false;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    --  Get Parameters
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
    END LOOP; --  Get Parameter
    SELECT PROCESSED,
      POSTED,
      AD_Org_ID,
      AD_Client_ID,
      C_CASHBOOK_ID, DateAcct
    INTO v_Processed,
      v_Posted,
      v_AD_Org_ID,
      v_AD_Client_ID,
      v_C_CashBook_ID, v_dateCash
    FROM C_CASH
    WHERE C_Cash_ID=v_Record_ID;
    /* Not needed: payments are updated to pending status
    SELECT COUNT(*) INTO v_Count
    FROM C_CASHLINE
    WHERE C_CASH_ID = v_Record_ID
    AND C_ORDER_ID IS NOT NULL
    AND C_DEBT_PAYMENT_ID IS NOT NULL;
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID;
    IF (v_Processed = 'Y' AND v_Count>0) THEN
    v_Message := '@AlreadyPosted@';
    v_Result := 0;
    FINISH_PROCESS := true;
    END IF;
    */
    IF(NOT FINISH_PROCESS) THEN
      IF(v_Posted='Y') THEN
        RAISE EXCEPTION '%', '@CashDocumentPosted@' ; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    -- Check if there are lines document does
    if (select count(*) from  C_CASHLINE where C_CASH_id=V_Record_ID)=0 then
          RAISE EXCEPTION '%', '@NoLinesInDoc@';
    END IF;
    IF(NOT FINISH_PROCESS) THEN
      DECLARE
        v_Settlement_Cancel VARCHAR(32):=NULL; --OBTG:VARCHAR2--
        CurDebtPaymentOrder RECORD;
      BEGIN
        /*
        *  Reversing process
        */
        IF(v_Processed='Y') THEN
          v_ResultStr:='Reversed';
          UPDATE C_CASH
            SET PROCESSED='N',
            --ENDINGBALANCE=0,
            STATEMENTDIFFERENCE=NULL
          WHERE C_CASH_ID=v_Record_ID;

          SELECT MAX(S.C_SETTLEMENT_ID)
          INTO v_Settlement_Cancel
          FROM C_DEBT_PAYMENT DP,
            C_SETTLEMENT S
          WHERE DP.C_SETTLEMENT_CANCEL_ID=S.C_SETTLEMENT_ID
            AND DP.C_CASHLINE_ID IN
            (SELECT C_CASHLINE_ID FROM C_CASHLINE  WHERE C_CASH_ID=v_Record_ID)
            AND S.DOCUMENTNO LIKE '*CP*%';


     UPDATE C_DEBT_PAYMENT
            SET C_CASHLINE_ID=NULL
          WHERE C_CASHLINE_ID IN
            (SELECT C_CASHLINE_ID
            FROM C_CASHLINE
            WHERE C_CASH_ID=v_Record_ID
              AND CashType IN('O', 'P'));--To be fixed. Cash type ='O' is deprecated. Added by P.Sarobe

          IF(v_Settlement_Cancel IS NOT NULL) THEN --This is the generated settlement (it only can be one)
           DELETE FROM FACT_ACCT
            WHERE AD_TABLE_ID = '800019'
            AND RECORD_ID = v_Settlement_Cancel;

      UPDATE C_Settlement set posted='N' where c_Settlement_ID= v_Settlement_Cancel;

            PERFORM C_SETTLEMENT_POST(NULL, v_Settlement_Cancel) ;
            UPDATE C_DEBT_PAYMENT
              SET C_SETTLEMENT_CANCEL_ID=NULL,
              CANCEL_PROCESSED='N',
              ISPaid='N'
            WHERE C_SETTLEMENT_CANCEL_ID=v_Settlement_Cancel;
            DELETE FROM C_SETTLEMENT WHERE C_SETTLEMENT_ID=v_Settlement_Cancel;
          END IF;

         --To be fixed. We are doing the same 'IsPaid' below. Added by P.Sarobe
     UPDATE C_DEBT_PAYMENT
            SET ISPaid='N'
          WHERE c_debt_payment_id IN
            (SELECT C_DEBT_PAYMENT_ID
            FROM C_CASHLINE
            WHERE C_CASH_ID=v_Record_ID
              AND CashType IN('O', 'P'));--To be fixed. Cash type ='O' is deprecated. Added by P.Sarobe

          -- This is done to be compatible with old versions. To be Fixed
          FOR CurDebtPaymentOrder IN
            (SELECT cl.C_CashLine_ID,
              cl.C_Debt_Payment_ID
            FROM C_CASHLINE cl
            WHERE cl.C_CASH_ID=v_Record_ID
              AND CASHTYPE='O'
              AND C_Order_ID IS NOT NULL
            )
          LOOP

            UPDATE C_CashLine
              SET C_Debt_Payment_ID=NULL
            WHERE C_CashLine_ID=CurDebtPaymentOrder.C_CashLine_ID;
            DELETE
            FROM C_DEBT_PAYMENT
            WHERE C_DEBT_PAYMENT_ID=CurDebtPaymentOrder.C_Debt_Payment_ID;
          END LOOP;
          FINISH_PROCESS:=true;
        END IF; --v_Processed = 'Y'
      END;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
      /*
      *  Checking Restrictions
      */
      -- Check the header belongs to a organization where transactions are posible and ready to use
      SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
      INTO v_is_ready, v_is_tr_allow
      FROM C_CASH, AD_Org, AD_OrgType
      WHERE AD_Org.AD_Org_ID=C_CASH.AD_Org_ID
      AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
      AND C_CASH.C_CASH_ID=v_Record_ID;
      IF (v_is_ready='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
      END IF;
      IF (v_is_tr_allow='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
      END IF;
      
      SELECT AD_ORG_CHK_DOCUMENTS('C_CASH', 'C_CASHLINE', v_Record_ID, 'C_CASH_ID', 'C_CASH_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;
      
      SELECT AD_ORG_CHK_DOC_PAYMENTS('C_CASH', 'C_CASHLINE', v_Record_ID, 'C_CASH_ID', 'C_CASH_ID', 'C_DEBT_PAYMENT_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@PaymentsAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;
         
      -- Check the period control is opened (only if it is legal entity with accounting)
      -- Gets the BU or LE of the document
      SELECT AD_GET_DOC_LE_BU('C_CASH', v_Record_ID, 'C_CASH_ID', 'LE')
      INTO v_org_bule_id
      FROM DUAL;
      
      SELECT AD_OrgType.IsAcctLegalEntity
      INTO v_isacctle
      FROM AD_OrgType, AD_Org
      WHERE AD_Org.AD_OrgType_ID = AD_OrgType.AD_OrgType_ID
      AND AD_Org.AD_Org_ID=v_org_bule_id;
      
      IF (v_isacctle='Y') THEN
        SELECT C_CHK_OPEN_PERIOD(v_AD_Org_ID, v_dateCash, 'CMC', NULL) 
        INTO v_available_period
        FROM DUAL;
        
        IF (v_available_period<>1) THEN
          RAISE EXCEPTION '%', '@PeriodNotAvailable@'; --OBTG:-20000--
        END IF;
      END IF;
        
      v_ResultStr:='CheckingRestrictions - C_CASH ORG IS IN C_CASHBOOK ORG TREE';
      SELECT COUNT(*)
      INTO v_count
      FROM C_CASH,
        C_CASHBOOK
      WHERE C_CASH.C_CASHBOOK_ID=C_CASHBOOK.C_CASHBOOK_ID
        AND NOT (Ad_Isorgincluded(C_CASH.AD_ORG_ID, C_CASHBOOK.AD_ORG_ID, C_CASHBOOK.AD_CLIENT_ID)<>-1
            OR Ad_Isorgincluded(C_CASHBOOK.AD_ORG_ID, C_CASH.AD_ORG_ID, C_CASHBOOK.AD_CLIENT_ID)<>-1)
        AND C_CASH_ID=v_Record_ID;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@NotCorrectOrgCashbook@' ; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN--To be Fixed. Cash type='O' is deprecated. Added by P.Sarobe
      v_ResultStr:='CheckingRestrictions - C_CASH ORG IS IN C_ORDER ORG TREE';
      SELECT COUNT(*),
        MAX(cl.Line)
      INTO v_count,
        v_line
      FROM C_CASH c,
        C_CASHLINE cl,
        C_ORDER o,
        C_BPARTNER bp
      WHERE c.C_CASH_ID=cl.C_CASH_ID
        AND c.C_CASH_ID=v_Record_ID
        AND cl.C_ORDER_ID=o.C_ORDER_ID
        AND o.C_BPARTNER_ID=bp.C_BPARTNER_ID
        AND (Ad_Isorgincluded(o.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1
        OR Ad_Isorgincluded(o.AD_ORG_ID, c.AD_ORG_ID, c.AD_CLIENT_ID)=-1);
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@NotCorrectOrgOrderCashLine@' ; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
      v_ResultStr:='CheckingRestrictions - C_CASH ORG IS IN C_DEBT_PAYMENT ORG TREE';
      SELECT COUNT(*),
        MAX(cl.Line)
      INTO v_count,
        v_line
      FROM C_CASH c,
        C_CASHLINE cl,
        C_DEBT_PAYMENT l,
        C_BPARTNER bp
      WHERE c.C_CASH_ID=cl.C_CASH_ID
        AND c.C_CASH_ID=v_Record_ID
        AND cl.C_DEBT_PAYMENT_ID=l.C_DEBT_PAYMENT_ID
        AND l.C_BPARTNER_ID=bp.C_BPARTNER_ID
        AND(Ad_Isorgincluded(l.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1 --To be deprecated, to be fixed. This Check restriction should be checked when debt payment is created. Added by PSarobe
        OR Ad_Isorgincluded(l.AD_ORG_ID, c.AD_ORG_ID, c.AD_CLIENT_ID)=-1) ;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@NotCorrectOrgDebtpaymentCashLine@' ; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
        --To be fixed. Cash type='O' to be deprecated. Added by P.Sarobe
    IF(NOT FINISH_PROCESS) THEN
      SELECT COUNT(*),
        MAX(cl.Line)
      INTO v_count,
        v_line
      FROM C_CASHLINE cl
      WHERE cl.C_Cash_ID=v_Record_ID
        AND cl.CASHTYPE='O'
        AND NOT EXISTS
        (SELECT 1
        FROM C_ORDERLINE ol
        WHERE ol.C_Order_ID=cl.C_Order_ID
          AND ol.QTYORDERED<>ol.QTYINVOICED
        )
        ;
      IF v_count>0 THEN
        v_Message:='@CashOrderInvoiced@. Line:'||v_line;
        v_Result:=0;
        FINISH_PROCESS:=true;
      END IF;
    END IF;--FINISH_PROCESS
        --Until here to be fixed, to be deprecated because of the cahstype='O'
    IF(NOT FINISH_PROCESS) THEN
      SELECT COUNT(*),
        MAX(cl.Line)
      INTO v_count,
        v_line
      FROM C_CASHLINE cl,
        C_DEBT_PAYMENT dp
      WHERE cl.C_Cash_ID=v_Record_ID
        AND cl.CASHTYPE='P'
        AND cl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        AND cl.C_Currency_ID=dp.C_Currency_ID
        AND
        CASE dp.IsReceipt WHEN 'Y' THEN -- If IsReceipt = N, amount*-1
          (dp.Amount-coalesce(dp.WriteOffAmt,0)) ELSE (coalesce(dp.WriteOffAmt,0)-dp.Amount)
        END
        <>(cl.Amount+coalesce(cl.WriteOffAmt,0)) ;
      IF v_count>0 THEN
       RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@DebtAmountsSamemoneyNoMatch@' ; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
      SELECT COUNT(*),
        MAX(cl.Line)
      INTO v_count,
        v_line
      FROM C_CASHLINE cl,
        C_CASH c,
        C_DEBT_PAYMENT dp
      WHERE cl.C_Cash_ID=c.C_Cash_ID
        AND cl.C_Cash_ID=v_Record_ID
        AND cl.CASHTYPE='P'
        AND cl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        AND cl.C_Currency_ID<>dp.C_Currency_ID
        AND
        CASE dp.IsReceipt WHEN 'Y' THEN -- If IsReceipt = N, amount*-1
          (coalesce(dp.Amount,0)-coalesce(dp.WriteOffAmt,0)) ELSE (coalesce(dp.WriteOffAmt,0)-coalesce(dp.Amount,0))
        END
        <>C_Currency_Round(C_Currency_Convert((coalesce(cl.Amount,0) + coalesce(cl.WriteOffAmt,0)), cl.C_Currency_ID, dp.C_Currency_ID, c.DateAcct, NULL, c.AD_Client_ID, c.AD_Org_ID), dp.C_Currency_ID, NULL) ;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@DebtAmountsDifferentMoneyNoMatch@' ; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
      SELECT COUNT(*), MAX(cl.C_CASHLINE_ID)
      INTO v_count, v_CashLine_ID
      FROM C_CASHLINE cl,
        C_DEBT_PAYMENT dp
      WHERE cl.C_Cash_ID=v_Record_ID
        AND cl.CASHTYPE='P'
        AND cl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        AND C_Debt_Payment_Status(dp.C_SETTLEMENT_CANCEL_ID, dp.Cancel_Processed, dp.Generate_Processed, dp.IsPaid, dp.IsValid, dp.C_CashLine_ID, dp.C_BankStatementLine_ID) NOT IN('P', 'A') ;
                IF v_count!=0 THEN
                --Added by P.Sarobe. New messages
                  SELECT line, c_Debt_Payment_ID INTO v_line, v_C_Debt_Payment_Id
                  FROM C_CASHLINE WHERE C_CASHLINE_ID=v_CashLine_ID;

                  SELECT c_Bankstatementline_Id, c_cashline_id, c_settlement_cancel_id, ispaid, cancel_processed
                  INTO v_Bankstatementline_ID, v_CashLine_ID, v_Settlement_Cancel_ID, v_ispaid, v_Cancel_Processed
                  FROM C_DEBT_PAYMENT WHERE C_Debt_Payment_ID = v_C_Debt_Payment_Id;
                           IF v_Bankstatementline_ID IS NOT NULL THEN
                                 SELECT C_BANKSTATEMENT.NAME, C_BANKSTATEMENT.STATEMENTDATE
                                 INTO v_nameBankstatement, v_dateBankstatement
                                 FROM C_BANKSTATEMENT, C_BANKSTATEMENTLINE
                                 WHERE C_BANKSTATEMENT.C_BANKSTATEMENT_ID = C_BANKSTATEMENTLINE.C_BANKSTATEMENT_ID
                                 AND C_BANKSTATEMENTLINE.C_BANKSTATEMENTLINE_ID = v_Bankstatementline_ID;
                         RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@ManagedDebtPaymentBank@'||v_nameBankstatement||' '||'@Bydate@'||v_dateBankstatement ; --OBTG:-20000--
                           END IF;
                           IF v_CashLine_ID IS NOT NULL THEN--This is also checked in the unique index C_CASHLINE_DEBT_PAYMENT
                                 SELECT C_CASH.NAME, C_CASH.STATEMENTDATE
                                 INTO v_nameCash, v_dateCash
                                 FROM C_CASH, C_CASHLINE
                                 WHERE C_CASH.C_CASH_ID = C_CASHLINE.C_CASH_ID
                                 AND C_CASHLINE.C_CASHLINE_ID = v_CashLine_ID;
                         RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@ManagedDebtPaymentCash@'||v_nameCash||' '||'@Bydate@'||v_dateCash ; --OBTG:-20000--
                           END IF;
                           IF v_Cancel_Processed='Y' AND v_ispaid='N' THEN
                                 SELECT documentno, datetrx
                                 INTO v_documentno_Settlement, v_dateSettlement
                                 FROM C_SETTLEMENT
                                 WHERE C_SETTLEMENT_ID = v_Settlement_Cancel_ID;
                                 RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@ManagedDebtPaymentCancel@'||v_documentno_Settlement||' '||'@Bydate@'||v_dateSettlement ; --OBTG:-20000--
                           END IF;
        END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
          SELECT COUNT(*), MAX(C_Debt_Payment_ID)
          INTO v_count, v_C_Debt_Payment_Id
          FROM
          --Subquery checks if there are duplicates debt payments for the same cash
          (SELECT dp.C_Debt_Payment_ID
        FROM C_CASHLINE cl,
          C_DEBT_PAYMENT dp
        WHERE cl.C_Cash_ID=v_Record_ID
          AND cl.CASHTYPE='P'
          AND cl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        GROUP BY dp.C_Debt_Payment_ID
        HAVING COUNT(*)>1
                )A;
      IF v_count>0 THEN
          --Added by PSarobe. This is also checked in the unique index C_CASHLINE_DEBT_PAYMENT
                 FOR Cur_CashlineDebtpayment IN (SELECT line
                                                                                FROM c_cashline
                                                                                WHERE c_cashline.c_cash_id=v_Record_ID
                                                                                AND c_cashline.c_debt_payment_id=v_C_Debt_Payment_Id) LOOP
                 v_Message:=v_Message||Cur_CashlineDebtpayment.line||', ';
                 END LOOP;
                 RAISE EXCEPTION '%', '@Inlines@'||v_Message||' '||'@Samedebtpayment@' ; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN --To be fixed because of cashtype='O'. Cashtype='O' to be deprecated
      SELECT COUNT(*),
        MAX(Line)
      INTO v_count,
        v_line
      FROM C_CASHLINE cl
      WHERE cl.C_Cash_ID=v_Record_ID
        AND((cl.CASHTYPE='O'
        AND C_ORDER_ID IS NULL)
        OR(cl.CASHTYPE='P'
        AND C_DEBT_PAYMENT_ID IS NULL)
        OR(cl.CASHTYPE NOT IN('O', 'P')
        AND(C_ORDER_ID IS NOT NULL
        OR C_DEBT_PAYMENT_ID IS NOT NULL))) ;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@WrongLineTypeAndReferenceCash@'; --OBTG:-20000--
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
      /**
      *  Generate C_debt_payment for cashline with order type
      */
      /* Now this goes to c_order_post ALO
      DECLARE
      v_debtPaymentID VARCHAR(32); --OBTG:varchar2--
      CurCashLinesOrder RECORD;
      BEGIN
      FOR CurCashLinesOrder IN (SELECT o.AD_CLIENT_ID, o.AD_ORG_ID, o.ISSOTRX, o.DOCUMENTNO, bp.NAME, o.POREFERENCE, o.C_ORDER_ID, o.C_BPARTNER_ID,
      o.C_CURRENCY_ID, cl.C_CASHLINE_ID, o.PAYMENTRULE, C_Currency_Convert((cl.Amount + cl.WriteOffAmt),
      cl.C_Currency_ID, o.C_Currency_ID, c.DateAcct, NULL, c.AD_Client_ID, c.AD_Org_ID) AMT,
      c.STATEMENTDATE, o.C_PROJECT_ID
      FROM C_CASHLINE cl, C_ORDER o, C_BPARTNER bp, C_CASH c
      WHERE cl.C_ORDER_ID = o.C_ORDER_ID
      AND cl.C_CASH_ID = v_Record_ID
      AND bp.C_BPARTNER_ID = o.C_BPARTNER_ID
      AND C.C_CASH_ID = cl.C_CASH_id) LOOP
      SELECT * INTO  v_debtPaymentID FROM Ad_Sequence_Next('C_Debt_Payment', v_Record_ID);
      INSERT INTO C_DEBT_PAYMENT(C_DEBT_PAYMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY,
      ISRECEIPT, C_SETTLEMENT_CANCEL_ID, C_SETTLEMENT_GENERATE_ID, DESCRIPTION,
      C_ORDER_ID, C_BPARTNER_ID,
      C_CURRENCY_ID, C_CASHLINE_ID, C_BANKACCOUNT_ID, C_CASHBOOK_ID, PAYMENTRULE,
      ISPAID, AMOUNT, WRITEOFFAMT, DATEPLANNED, ISMANUAL, ISVALID,
      C_BANKSTATEMENTLINE_ID, CHANGESETTLEMENTCANCEL, CANCEL_PROCESSED, GENERATE_PROCESSED, c_project_id)
      VALUES
      (v_debtPaymentID, CurCashLinesOrder.AD_CLIENT_ID, CurCashLinesOrder.AD_ORG_ID, 'Y', TO_DATE(NOW()), v_User, TO_DATE(NOW()), v_User,
      CurCashLinesOrder.IsSOTrx, NULL, NULL, 'Order No: ' || CurCashLinesOrder.DOCUMENTNO || ' (' || CurCashLinesOrder.Name || (CASE WHEN CurCashLinesOrder.POREFERENCE IS NULL THEN '' ELSE ' .Ref:'||TO_CHAR(CurCashLinesOrder.POREFERENCE) END) || ')',
      CurCashLinesOrder.C_ORDER_ID, CurCashLinesOrder.C_BPartner_ID,
      CurCashLinesOrder.C_CURRENCY_ID, NULL,NULL,v_C_CashBook_ID, CurCashLinesOrder.PAYMENTRULE,
      'N',(CASE CurCashLinesOrder.IsSOTrx WHEN 'Y' THEN CurCashLinesOrder.AMT ELSE (-1)*CurCashLinesOrder.AMT END),0,CurCashLinesOrder.STATEMENTDATE,'N','Y',
      NULL,'N','N','N',CurCashLinesOrder.C_PROJECT_ID);
      UPDATE C_CASHLINE
      SET C_DEBT_PAYMENT_ID = v_debtPaymentID
      WHERE C_CASHLINE_ID = CurCashLinesOrder.C_CASHLINE_ID;
      END LOOP;
      END;
      */
      /**
      *  Generate C_Settlement
      */
      SELECT COUNT(*)
      INTO v_count
      FROM C_CASHLINE cl,
        C_DEBT_PAYMENT dp
      WHERE cl.C_Cash_ID=v_Record_ID
        AND cl.CASHTYPE IN('O', 'P')
        AND cl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        AND C_Debt_Payment_Status(dp.C_SETTLEMENT_CANCEL_ID, dp.Cancel_Processed, dp.Generate_Processed, dp.IsPaid, dp.IsValid, dp.C_CashLine_ID, dp.C_BankStatementLine_ID)='P';
      v_ResultStr:='GettingCashBookInfo';
      SELECT cb.C_Currency_ID,
        c.DateAcct
      INTO v_CB_Currency_ID,
        v_CB_Date
      FROM C_CASHBOOK cb,
        C_CASH c
      WHERE cb.C_CashBook_ID=c.C_CashBook_ID
        AND c.C_Cash_ID=v_Record_ID;
      IF(v_count>0) THEN
        v_SettlementDocType_ID:=Ad_Get_DocType(v_AD_Client_ID, v_AD_Org_ID, 'STT') ;
        SELECT * INTO  v_settlementID FROM Ad_Sequence_Next('C_Settlement', v_Record_ID) ;
        SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(v_SettlementDocType_ID,  v_AD_Org_ID, 'Y') ;
        IF(v_DocumentNo IS NULL) THEN
          SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Settlement',  v_AD_Org_ID, 'Y') ;
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
        SELECT v_settlementID,
          AD_Client_ID, AD_Org_ID, 'Y', TO_DATE(NOW()),
          UpdatedBy, TO_DATE(NOW()), UpdatedBy, '*CP*'||v_DocumentNo,
          v_CB_Date, v_CB_Date, 'B', v_SettlementDocType_ID,
           'N', 'N', 'N', v_CB_Currency_ID,
          C_PROJECT_ID, C_CAMPAIGN_ID, C_ACTIVITY_ID, USER1_ID,
          USER2_ID, 'N', 'Y'
        FROM C_CASH
        WHERE C_Cash_ID=v_Record_ID;
        UPDATE C_DEBT_PAYMENT
          SET C_SETTLEMENT_CANCEL_ID=v_settlementID,
          IsPaid='Y'
        WHERE C_DEBT_PAYMENT.C_Debt_Payment_ID IN
          (SELECT C_Debt_Payment_ID FROM C_CASHLINE WHERE C_Cash_ID=v_Record_ID)
          AND C_Debt_Payment_Status(C_DEBT_PAYMENT.C_SETTLEMENT_CANCEL_ID, C_DEBT_PAYMENT.Cancel_Processed, C_DEBT_PAYMENT.Generate_Processed, C_DEBT_PAYMENT.IsPaid, C_DEBT_PAYMENT.IsValid, C_DEBT_PAYMENT.C_CashLine_ID, C_DEBT_PAYMENT.C_BankStatementLine_ID)='P';
        PERFORM C_SETTLEMENT_POST(NULL, v_settlementID) ;
      END IF;
    END IF;--FINISH_PROCESS
    IF(NOT FINISH_PROCESS) THEN
      /**
      *  Update Balances + De-Activate + Conciliate Debt_Payments
      */
      DECLARE
        v_Total NUMERIC:=0;
        v_Currency_ID VARCHAR(32):=NULL; --OBTG:VARCHAR2--
        -- Lines
        Cur_Lines RECORD;
      BEGIN
        -- Calculate Tital
        FOR Cur_Lines IN
          (SELECT *  FROM C_CASHLINE  WHERE C_Cash_ID=v_Record_ID)
        LOOP
          v_ResultStr:='GettingTrxCurrency';
          -- Get Debt_Payment Currency and conciliate Debt/Payments
          IF(Cur_Lines.CashType IN('O', 'P') AND Cur_Lines.C_Debt_Payment_ID IS NOT NULL) THEN
            UPDATE C_DEBT_PAYMENT
              SET C_CashLine_ID=Cur_Lines.C_CashLine_ID
            WHERE C_Debt_Payment_ID=Cur_Lines.C_Debt_Payment_ID;
            SELECT C_Currency_ID
            INTO v_Currency_ID
            FROM C_DEBT_PAYMENT
            WHERE C_Debt_Payment_ID=Cur_Lines.C_Debt_Payment_ID;
          END IF;
          -- Assume CashBook Currency for Charge
          /* Lines are in cashbook currency
     IF(v_Currency_ID IS NULL) THEN
            v_Currency_ID:=v_CB_Currency_ID;
          END IF;
          v_ResultStr:='CalculatingSum';
          IF(v_Currency_ID<>v_CB_Currency_ID) THEN
            v_Total:=v_Total + C_Currency_Convert(Cur_Lines.Amount, v_Currency_ID, v_CB_Currency_ID, v_CB_Date, NULL, Cur_Lines.AD_Client_ID, Cur_Lines.AD_Org_ID) ;
          ELSE
            v_Total:=v_Total + Cur_Lines.Amount;
          END IF;
     */
     v_Total:=v_Total + Cur_Lines.Amount;
        END LOOP;
        --
        RAISE NOTICE '%','CashJournal Complete - Total=' || v_Total ;
        v_ResultStr:='UpdatingRecord';
        UPDATE C_CASH
          SET StatementDifference=v_Total,
          EndingBalance=BeginningBalance + v_Total,
          Processed='Y',
          Updated=TO_DATE(NOW())
        WHERE C_Cash_ID=v_Record_ID;
        -- Synchronize Client/Org Ownership
        UPDATE C_CASHLINE
          SET AD_Client_ID=v_AD_Client_ID,
          AD_Org_ID=v_AD_Org_ID
        WHERE C_Cash_ID=v_Record_ID
          AND(AD_Client_ID<>v_AD_Client_ID
          OR AD_Org_ID<>v_AD_Org_ID) ;
      END;
    END IF;--FINISH_PROCESS
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, v_User, 'N', 1, v_Message) ;
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


ALTER FUNCTION public.c_cash_post(p_pinstance_id character varying) OWNER TO tad;




-- Function: c_remittance_trg()

-- DROP FUNCTION c_remittance_trg();

CREATE OR REPLACE FUNCTION c_remittance_trg()
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
 Contributions: Hotfix: Unpost must be allowed although there are Settlements.
        The settlements may be deleted.
        Otherwise it is not possible to reopen an Invoice with settlements.
        The settlement on the Invoice may be deleted manually.
    ----> Replace old Trigger with this DUMMY
******************************************************************************************************************************/
v_DateNull TIMESTAMP := TO_DATE('31-12-9999','DD-MM-YYYY');
    
BEGIN
    
    IF 'N'='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

END 
; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_remittance_trg() OWNER TO tad;


CREATE OR REPLACE FUNCTION c_remittanceline_trg()
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
 Contributions:Hotfix: Unpost must be allowed although there are Settlements.
        The settlements may be deleted.
        Otherwise it is not possible to reopen an Invoice with settlements.
        The settlement on the Invoice may be deleted manually.
    ----> Replace old Trigger with this DUMMY
******************************************************************************************************************************/
v_DateNull TIMESTAMP := TO_DATE('31-12-9999','DD-MM-YYYY');
    
BEGIN
    
    IF 'N'='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    

END 

; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_remittanceline_trg() OWNER TO tad;



CREATE OR REPLACE FUNCTION c_dp_management_chk_restr_trg()
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
 Contributions: Hotfix: Unpost must be allowed although there are Settlements.
        The settlements may be deleted.
        Otherwise it is not possible to reopen an Invoice with settlements.
        The settlement on the Invoice may be deleted manually.
    ----> Replace old Trigger with this DUMMY
******************************************************************************************************************************/
v_DateNull TIMESTAMP := TO_DATE('31-12-9999','DD-MM-YYYY');
    
BEGIN
    
    IF 'N'='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    

END 

; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_dp_management_chk_restr_trg() OWNER TO tad;

CREATE OR REPLACE FUNCTION c_dpmline_chk_restrictions_trg()
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

/* Contributions:Hotfix: Unpost must be allowed although there are Settlements.
        The settlements may be deleted.
        Otherwise it is not possible to reopen an Invoice with settlements.
        The settlement on the Invoice may be deleted manually.
    ----> Replace old Trigger with this DUMMY
******************************************************************************************************************************/
v_DateNull TIMESTAMP := TO_DATE('31-12-9999','DD-MM-YYYY');
    
BEGIN
    
    IF 'N'='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

    

END 

; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_dpmline_chk_restrictions_trg() OWNER TO tad;




CREATE OR REPLACE FUNCTION c_settlement_post(p_pinstance_id character varying, p_settlement_id character varying)
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
 Contributions:
 Reorganized Code,
 Indtroduced discount
 Implemented Payment Monitor here
*********************************************************************************************************************************/
  --  Logistice
  v_ResultStr VARCHAR(2000):=''; 
  v_Message VARCHAR(2000):=''; 
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32) ; 
  v_AD_User_ID VARCHAR(32) ; 
  v_AD_Client_ID VARCHAR(32) ; 
  v_AD_Org_ID VARCHAR(32) ; 
  v_Processed VARCHAR(60) ;
  v_Currency VARCHAR(32); 
  v_Date TIMESTAMP;
  v_DateAcct TIMESTAMP;
  v_CashBook_ISO_Code VARCHAR(10) ;
  v_Record_Description VARCHAR(2000):=''; 
  v_Debt_Payment_ID VARCHAR(32) ; 
  v_isGenerated char(1) ;
  --Added by Psarobe
  v_Datetrx TIMESTAMP;
  v_nameBankstatement VARCHAR; 
  v_dateBankstatement TIMESTAMP;
  v_nameCash VARCHAR; 
  v_dateCash TIMESTAMP;
  v_documentno_Settlement VARCHAR(20); 
  v_dateSettlement TIMESTAMP;
  v_column_identifier VARCHAR(4000); 
  v_Cashline_ID VARCHAR(32); 
  v_Bankstatement_ID VARCHAR(32); 
  v_DocType_ID VARCHAR(32); 
  v_is_included NUMERIC:=0;
  v_available_period NUMERIC:=0;
  v_is_ready AD_Org.IsReady%TYPE;
  v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
  v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
  v_org_bule_id AD_Org.AD_Org_ID%TYPE;
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    --  Parameter Variables
    v_Aux NUMERIC;
    v_CanceledNotChargeAmt NUMERIC:=0;
    v_GeneratedAmt NUMERIC:=0;
    v_ChargedAmt NUMERIC:=0;
    --
    v_ForcedOrg NUMERIC;
    v_ManualAmt NUMERIC:=0;
    FINISH_PROCESS BOOLEAN:=false;
    Cur_Debts RECORD;
    Cur_Lines RECORD;
    p_CashBook VARCHAR(32) ; 
    p_Cash VARCHAR(32) ; 
    p_CashLine VARCHAR(32) ; 
    p_Line NUMERIC;
    p_Amount NUMERIC;
  BEGIN
    IF(p_PInstance_ID IS NOT NULL) THEN
      --  Update AD_PInstance
      RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
      v_ResultStr:='PInstanceNotFound';
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
      --  Get Parameters
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
      END LOOP; --  Get Parameter
      RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    ELSE
      RAISE NOTICE '%','--<<C_Settlement_Post>>' ;
      v_Record_ID:=p_Settlement_ID;
    END IF;
    SELECT UpdatedBy, AD_Client_ID, AD_Org_ID, Processed,
          C_Currency_ID, DATETRX, DateAcct, IsGenerated, C_DocType_ID
    INTO v_AD_User_ID, v_AD_Client_ID, v_AD_Org_ID, v_Processed,
            v_Currency, v_Date, v_DateAcct, v_IsGenerated, v_DocType_ID
    FROM C_SETTLEMENT
    WHERE C_Settlement_ID=v_Record_ID;
    -- Check if there are lines document does
    if (select count(*) from  C_Debt_Payment_Cancel where c_settlement_id=V_Record_ID)=0 and (select count(*) from C_Debt_Payment_Generate  where c_settlement_id=V_Record_ID)=0 then
        RAISE EXCEPTION '%', '@NoLinesInDoc_c_settlement_post@';
    END IF;
    IF(v_Processed='Y') THEN
          --Checking restrictions for unprocessing
          SELECT COUNT(*), MAX(C_DEBT_PAYMENT_ID)
          INTO v_Aux, v_Debt_Payment_ID
          FROM C_DEBT_PAYMENT
          WHERE(C_BANKSTATEMENTLINE_ID IS NOT NULL
              OR C_CASHLINE_ID IS NOT NULL)
              AND(C_SETTLEMENT_GENERATE_ID=v_Record_ID
              OR C_SETTLEMENT_CANCEL_ID=v_Record_ID) ;
          IF v_Aux<>0 THEN
              SELECT AD_COLUMN_IDENTIFIER_STD('C_Debt_Payment',TO_CHAR(C_DEBT_PAYMENT.C_Debt_Payment_Id)), C_BANKSTATEMENTLINE_ID, C_CASHLINE_ID
                    INTO v_column_identifier, v_Bankstatement_ID,v_Cashline_ID
                    FROM C_DEBT_PAYMENT WHERE C_DEBT_PAYMENT_ID = v_Debt_Payment_ID;
              IF v_Bankstatement_ID IS NOT NULL THEN
                        SELECT  C_BANKSTATEMENT.NAME, C_BANKSTATEMENT.STATEMENTDATE
                        INTO v_nameBankstatement, v_dateBankstatement
                          FROM C_BANKSTATEMENT, C_BANKSTATEMENTLINE
                        WHERE C_BANKSTATEMENT.C_BANKSTATEMENT_ID = C_BANKSTATEMENTLINE.C_BANKSTATEMENT_ID
                        AND C_BANKSTATEMENTLINE.C_DEBT_PAYMENT_ID = v_Debt_Payment_ID;
                        RAISE EXCEPTION '%', '@Debtpayment@'||v_column_identifier||' '||'@ConciliatedDebtPaymentBank@'||v_nameBankstatement||' '||'@Bydate@'||v_dateBankstatement ; --OBTG:-20000--
              END IF;
              IF v_Cashline_ID IS NOT NULL THEN
                    SELECT C_CASH.NAME, C_CASH.STATEMENTDATE
                    INTO v_nameCash, v_dateCash
                    FROM C_CASH, C_CASHLINE
                    WHERE C_CASH.C_CASH_ID = C_CASHLINE.C_CASH_ID
                    AND C_CASHLINE.C_DEBT_PAYMENT_ID = v_Debt_Payment_ID;
                    RAISE EXCEPTION '%', '@Debtpayment@'||v_column_identifier||' '||'@ConciliatedDebtPaymentCash@'||v_nameCash||' '||'@Bydate@'||v_dateCash ; --OBTG:-20000--
              END IF;
          END IF;
         
          SELECT COUNT(*), MAX(C_Debt_Payment_Id)
          INTO v_Aux, v_Debt_Payment_ID
          FROM C_DEBT_PAYMENT
          WHERE C_SETTLEMENT_CANCEL_ID IS NOT NULL
            AND C_SETTLEMENT_GENERATE_ID=v_Record_ID;
          IF v_Aux<>0 THEN
              SELECT documentno, datetrx, AD_COLUMN_IDENTIFIER_STD('C_Debt_Payment', TO_CHAR(C_DEBT_PAYMENT.C_Debt_Payment_Id))
              INTO v_documentno_Settlement, v_dateSettlement, v_column_identifier
              FROM C_SETTLEMENT, C_DEBT_PAYMENT
              WHERE C_SETTLEMENT.C_Settlement_Id = C_DEBT_PAYMENT.C_settlement_cancel_Id
              and C_DEBT_PAYMENT.C_Debt_Payment_Id = v_Debt_Payment_ID;
                      RAISE EXCEPTION '%', '@Debtpayment@'||v_column_identifier||' '||'@GenerateDebtPaymentManaged@'||v_documentno_Settlement||' '||'@Bydate@'||v_dateSettlement ; --OBTG:-20000--
          END IF;
       
          SELECT COUNT(*)
          INTO v_Aux
          FROM C_SETTLEMENT
          WHERE POSTED='Y'
            AND C_SETTLEMENT_ID=v_Record_ID;
          --Direct accounting settlement verification is not necessary because it's controlled in the previous restriction
          IF v_Aux<>0 THEN
            RAISE EXCEPTION '%', '@SettlementDocumentPosted@' ; --OBTG:-20000--
          ELSE
                UPDATE C_SETTLEMENT
                  SET Processed='N',
                  UPDATED=TO_DATE(NOW()),
                  UPDATEDBY=v_AD_User_ID
                WHERE C_Settlement_ID=v_Record_ID;
                UPDATE C_DEBT_PAYMENT
                  SET Cancel_Processed='N',
                  UPDATED=TO_DATE(NOW()),
                  UPDATEDBY=v_AD_User_ID
                WHERE C_Settlement_Cancel_ID=v_Record_ID;
                UPDATE C_DEBT_PAYMENT
                  SET Generate_Processed='N',
                  isValid='N',
                  UPDATED=TO_DATE(NOW()),
                  UPDATEDBY=v_AD_User_ID
                WHERE C_Settlement_Generate_ID=v_Record_ID;
                IF v_IsGenerated='N' THEN
                      --Delete cashline generated from manual settlement with payed dps
                      DELETE
                      FROM C_CASHLINE
                      WHERE C_CASHLINE.C_DEBT_PAYMENT_ID IN
                        (SELECT C_DEBT_PAYMENT_ID
                        FROM C_DEBT_PAYMENT
                        WHERE C_SETTLEMENT_CANCEL_ID=v_Record_ID
                          OR C_SETTLEMENT_GENERATE_ID=v_Record_ID
                          AND IsPaid='Y'
                          AND PaymentRule IN('C', 'B'));
                END IF;
                v_Message:='@UnProcessedSettlement@';
          END IF; --Aux
      FINISH_PROCESS:=true;
    END IF; -- vProcessed
    IF(NOT FINISH_PROCESS) THEN
      /*
      *  Checking Restrictions
      */
      -- Check the header belongs to a organization where transactions are posible and ready to use
      SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
      INTO v_is_ready, v_is_tr_allow
      FROM C_SETTLEMENT, AD_Org, AD_OrgType
      WHERE AD_Org.AD_Org_ID=C_SETTLEMENT.AD_Org_ID
      AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
      AND C_SETTLEMENT.C_SETTLEMENT_ID=v_Record_ID;
      IF (v_is_ready='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
      END IF;
      IF (v_is_tr_allow='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
      END IF;

      SELECT AD_ORG_CHK_DOCUMENTS('C_SETTLEMENT', 'C_DEBT_PAYMENT', v_Record_ID, 'C_SETTLEMENT_ID', 'C_SETTLEMENT_GENERATE_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@PaymentsAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;

      SELECT AD_ORG_CHK_DOCUMENTS('C_SETTLEMENT', 'C_DEBT_PAYMENT', v_Record_ID, 'C_SETTLEMENT_ID', 'C_SETTLEMENT_CANCEL_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@PaymentsAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;

      -- Check the period control is opened (only if it is legal entity with accounting)
      -- Gets the BU or LE of the document
      SELECT AD_GET_DOC_LE_BU('C_SETTLEMENT', v_Record_ID, 'C_SETTLEMENT_ID', 'LE')
      INTO v_org_bule_id
      FROM DUAL;
      /*
      *  Checking Restrictions
      */
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
      /*
      *  Checking Restrictions
      */
      v_ResultStr:='CheckingRestrictions - C_DEBT_PAYMENT ORG IS IN C_BPARTNER ORG TREE';
      SELECT COUNT(*), AD_COLUMN_IDENTIFIER_STD ('C_Debt_Payment', TO_CHAR(MAX(c.C_Debt_Payment_Id)))
      INTO v_Aux, v_column_identifier
      FROM C_DEBT_PAYMENT c,
        C_BPARTNER bp
      WHERE(c.C_SETTLEMENT_CANCEL_ID=v_Record_ID
        OR c.C_SETTLEMENT_GENERATE_ID=v_Record_ID)
        AND c.C_BPARTNER_ID=bp.C_BPARTNER_ID
        AND Ad_Isorgincluded(c.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1;
      IF v_Aux>0 THEN
        RAISE EXCEPTION '%', '@OrgDebtpayment@'||v_column_identifier||' '||'@OrgdifferentBpartner@' ; --OBTG:-20000--
      END IF;

      /*
      *  Checking Restrictions
      */
      v_ResultStr:='CheckingRestrictions - C_DEBT_PAYMENT ORG IS IN C_BPARTNER ORG TREE';
      SELECT COUNT(*)
      INTO v_Aux
      FROM C_SETTLEMENT S,
        C_DocType
      WHERE C_DocType.DocBaseType IN ('STT','STM')
        AND AD_ISORGINCLUDED(S.AD_Org_ID,C_DocType.AD_Org_ID, S.AD_Client_ID) <> -1
        AND S.C_SETTLEMENT_ID = v_Record_ID
        AND S.C_DOCTYPE_ID = C_DocType.C_DOCTYPE_ID;
      IF v_Aux=0 THEN
        RAISE EXCEPTION '%', '@NotCorrectOrgDoctypeSettlement@' ; --OBTG:-20000--
      END IF;


  
      /*
      *  Checking Restrictions
      */
      v_ResultStr:='CheckingRestrictions - C_DEBT_PAYMENT MANUAL IS NOT SPLIT';
      SELECT COUNT(*), AD_COLUMN_IDENTIFIER_STD ('C_Debt_Payment', TO_CHAR(MAX(c.C_Debt_Payment_Id)))
      INTO v_Aux, v_column_identifier
      FROM C_DEBT_PAYMENT c
      WHERE c.C_SETTLEMENT_CANCEL_ID=v_Record_ID
      AND c.ISMANUAL = 'Y'
      AND c.ISPAID = 'N'
      AND NOT EXISTS (SELECT 1 FROM C_DEBT_PAYMENT D
      WHERE C.C_SETTLEMENT_CANCEL_ID = D.C_SETTLEMENT_CANCEL_ID
      AND C.ISRECEIPT = D.ISRECEIPT
      AND C.AMOUNT = AMOUNT*-1
      AND d.ISPAID = 'N');
      IF v_Aux>0 THEN
        RAISE EXCEPTION '%', '@ManualDebtpayment@'||' "'||v_column_identifier||'" '||'@CanNotBeSplit@' ; --OBTG:-20000--
      END IF;
 


      /*
      *  Checking Restrictions
      */
      v_ResultStr:='CheckingRestrictions - C_DEBT_PAYMENT ORG IS IN C_SETTLEMENT ORG TREE';
      SELECT COUNT(*), AD_COLUMN_IDENTIFIER_STD ('C_Debt_Payment', TO_CHAR(MAX(c.C_Debt_Payment_Id)))
      INTO v_Aux, v_column_identifier
      FROM C_DEBT_PAYMENT c,
        C_SETTLEMENT s
      WHERE(c.C_SETTLEMENT_CANCEL_ID=v_Record_ID
        OR c.C_SETTLEMENT_GENERATE_ID=v_Record_ID)
        AND s.C_SETTLEMENT_ID=v_Record_ID
        AND Ad_Isorgincluded(c.AD_ORG_ID, s.AD_ORG_ID, s.AD_CLIENT_ID)=-1;
      IF v_Aux>0 THEN
        RAISE EXCEPTION '%', '@OrgDebtpayment@'||v_column_identifier||' '||'@OrgdifferentSettlement@' ; --OBTG:-20000--
      END IF;
 
--To be fixed o deprecated. It should be imposible to do is
      /*
      *  Checking Restrictions
      */
      SELECT COUNT(*)
      INTO v_Aux
      FROM C_DEBT_PAYMENT p
      WHERE p.C_Settlement_Cancel_ID=v_Record_ID
        AND C_Debt_Payment_Status(p.C_SETTLEMENT_CANCEL_ID, p.Cancel_Processed, p.Generate_Processed, p.IsPaid, p.IsValid, p.C_CashLine_ID, p.C_BankStatementLine_ID)<>'P';
      -- If p_PInstance_ID is null there is not need to check Debt/Payment Status
      IF((v_Aux>0) AND(p_PInstance_ID IS NOT NULL)) THEN
        RAISE EXCEPTION '%', '@DebtPaymentNotPending@' ; --OBTG:-20000--
      END IF;
  --Until here to be deprecated
      /*
      *  END OF Checking Restrictions
      *****************************************************************************************+
      */  
    
      /*
      *  Checking AMOUNTS
      *  SZ: Added discount-Removed Witholding
      */
      v_ResultStr:='CheckingAmounts';
      --Calculating the non-paid amount to cancel
      SELECT COALESCE(SUM(C_Currency_Round(  C_Currency_Convert((Amount-WriteOffAmt-discountamt), C_Currency_ID, v_Currency, v_Date, NULL, v_AD_Client_ID, v_AD_Org_ID), v_Currency, NULL)), 0)
      INTO v_CanceledNotChargeAmt
      FROM C_Debt_Payment_V
      WHERE C_Settlement_Cancel_ID=v_Record_ID
        AND isActive='Y'
        AND isPaid='N';
      --Calculating the generated amount
      SELECT COALESCE(SUM(C_Currency_Round(  C_Currency_Convert(Amount, C_Currency_ID, v_Currency, v_Date, NULL, v_AD_Client_ID, v_AD_Org_ID), v_Currency, NULL)), 0)
      INTO v_GeneratedAmt
      FROM C_Debt_Payment_V
      WHERE C_Settlement_Generate_ID=v_Record_ID
        AND isActive='Y'
        AND isManual='N';
      --Calculating the applied amount
      SELECT COALESCE(SUM(C_Currency_Round(  C_Currency_Convert((Amount - WriteOffAmt-discountamt), C_Currency_ID, v_Currency, v_Date, NULL, v_AD_Client_ID, v_AD_Org_ID), v_Currency, NULL)), 0)
      INTO v_ChargedAmt
      FROM C_Debt_Payment_V
      WHERE(C_Settlement_Cancel_ID=v_Record_ID
        OR C_Settlement_Generate_ID=v_Record_ID)
        AND isActive='Y'
        AND isPaid='Y';
      v_ResultStr:='UpdatingSettlementAmounts';
      UPDATE C_SETTLEMENT
        SET Updated=TO_DATE(NOW()),
        UpdatedBy=v_AD_User_ID,
        CanceledNotChargeAmt=v_CanceledNotChargeAmt,
        GeneratedAmt=v_GeneratedAmt,
        ChargedAmt=v_ChargedAmt
      WHERE C_Settlement_ID=v_Record_ID;
      IF(v_CanceledNotChargeAmt<>v_GeneratedAmt) THEN
        RAISE EXCEPTION '%', '@SettlementNotMatch@' ; --OBTG:-20000--
      END IF;
      
 
      /*
      *  Checking AMOUNTS
      *  SZ:Removed Payment-Balancing and GL/Item 
      *  So it IS DEPRECATED
      */
      v_ResultStr:='CheckingAmounts';
      --Calculating the the amount of manual debt-payment items
      
      /*
      *  Updating Debt-Payment- Lines
      *  Updating BPartner-Credit Used
      */
      v_ResultStr:='UpdatingCancelLines';
      UPDATE C_DEBT_PAYMENT
        SET Updated=TO_DATE(NOW()),
        UpdatedBy=v_AD_User_ID,
        Cancel_Processed='Y'
      WHERE isActive='Y'
        AND C_Settlement_Cancel_ID=v_Record_ID;
      v_ResultStr:='UpdatingGenerateLines';
      UPDATE C_DEBT_PAYMENT
        SET Updated=TO_DATE(NOW()),
        UpdatedBy=v_AD_User_ID,
        Generate_Processed='Y',
        isValid='Y'
      WHERE isActive='Y'
        AND C_Settlement_Generate_ID=v_Record_ID;
      v_ResultStr:='UpdatingSOCreditUsed';
        FOR Cur_Debts IN
          (SELECT DISTINCT C_BPartner_ID
          FROM C_DEBT_PAYMENT
          WHERE C_Settlement_Cancel_ID=v_Record_ID
            OR C_Settlement_Generate_ID=v_Record_ID AND ISRECEIPT = 'Y'
          )
        LOOP
          PERFORM C_BP_SOCREDITUSED_REFRESH(Cur_Debts.C_BPartner_ID) ;
        END LOOP;

       /*
      *  Creating Cash-Lines when Cash is used
      *  
      */
      v_ResultStr:='CreatingCashLines';
        FOR Cur_Lines IN
              (SELECT dp.*,
                c.ISO_CODE,
                s.DateAcct
              FROM C_DEBT_PAYMENT dp,
                C_CURRENCY c,
                C_SETTLEMENT s
              WHERE dp.C_Settlement_Generate_ID=v_Record_ID
                AND s.C_SETTLEMENT_ID=dp.C_Settlement_Generate_ID
                AND dp.C_CURRENCY_ID=c.C_CURRENCY_ID
                AND dp.isActive='Y'
                AND dp.IsPaid='Y'
                AND dp.PaymentRule IN('C', 'B')
              )
         LOOP
            p_CashBook:=Cur_Lines.C_CashBook_ID;
            IF p_CashBook IS NULL THEN
              SELECT MAX(C_CashBook_ID)
              INTO p_CashBook
              FROM C_CASHBOOK
              WHERE AD_CLIENT_ID=v_AD_Client_ID
                AND ISACTIVE='Y'
                AND ISDEFAULT='Y';
              IF p_CashBook IS NULL THEN
                RAISE EXCEPTION '%', 'No default cash book' ; --OBTG:-20600--
              END IF;
            END IF;
         
            SELECT MAX(C.C_CASH_ID)
            INTO p_Cash
            FROM C_CASH C
            WHERE C.C_CASHBOOK_ID=p_CashBook
              AND C.DATEACCT=Cur_Lines.DateAcct
              AND C.PROCESSED='N';
            SELECT C_CURRENCY.ISO_CODE
            INTO v_CashBook_ISO_Code
            FROM C_CASHBOOK,
              C_CURRENCY
            WHERE C_CASHBOOK.C_CURRENCY_ID=C_CURRENCY.C_CURRENCY_ID
              AND C_CASHBOOK_ID=p_CashBook;
            IF(p_Cash IS NULL) THEN
                  v_ResultStr:='Creating C_Cash';
                  SELECT * INTO  p_Cash FROM Ad_Sequence_Next('C_Cash', v_AD_Org_ID) ;
                  INSERT
                  INTO C_CASH
                    (
                      C_Cash_ID, AD_Client_ID, AD_Org_ID, IsActive,
                      Created, CreatedBy, Updated, UpdatedBy,
                      C_CashBook_ID, NAME, StatementDate, DateAcct,
                      BeginningBalance, EndingBalance, StatementDifference, Processing,
                      Processed, Posted
                    )
                    VALUES
                    (
                      p_Cash, v_AD_Client_ID, v_AD_Org_ID, 'Y',
                      TO_DATE(NOW()), v_AD_User_ID, TO_DATE(NOW()), v_AD_User_ID,
                      p_CashBook, (TO_CHAR(Cur_Lines.DateAcct, 'YYYY-MM-DD') || ' ' || v_CashBook_ISO_Code), v_Date, v_Date,
                      0, 0, 0, 'N',
                      'N', 'N'
                    );
            END IF; --p_Cash IS NULL
            v_ResultStr:='Creating C_CashLine';
            SELECT * INTO  p_CashLine FROM Ad_Sequence_Next('C_CashLine', v_AD_Org_ID) ;
            SELECT COALESCE(MAX(LINE), 0) + 10
            INTO p_Line
            FROM C_CASHLINE
            WHERE C_CASH_ID=p_Cash;
                  p_Amount:=Cur_Lines.Amount - Cur_Lines.WriteOffAmt;
            IF Cur_Lines.isReceipt='N' THEN
                p_Amount:=p_Amount * -1;
            END IF;
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
                p_CashLine, v_AD_Client_ID, v_AD_Org_ID, 'Y',
                TO_DATE(NOW()), v_AD_User_ID, TO_DATE(NOW()), v_AD_User_ID,
                p_Cash, Cur_Lines.C_Debt_Payment_ID, p_Line, Cur_Lines.Description,
                p_Amount, 'P', Cur_Lines.C_Currency_ID, 0,
                0, 'Y'
              );
         END LOOP;--Cursor-Lines
      /*
      *  Updating Settlement
      *  
      */
      v_ResultStr:='UpdatingSettlement';
      UPDATE C_SETTLEMENT
        SET Updated=TO_DATE(NOW()),
        UpdatedBy=v_AD_User_ID,
        Processed='Y'
      WHERE C_Settlement_ID=v_Record_ID;
    END IF;--FINISH_PROCESS
    -- SZ: Update Payment-Monitor
    PERFORM zsfi_paymentmonitor(v_Record_ID);
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    IF(p_PInstance_ID IS NOT NULL) THEN
      RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
      PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
      RAISE NOTICE '%','--<<C_Settlement_Post finished>> ' || v_Message ;
    END IF;
    RETURN;
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
END ; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



-- Function: c_debt_payment_trg()

-- DROP FUNCTION c_debt_payment_trg();

CREATE OR REPLACE FUNCTION c_debt_payment_trg()
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
 Contributions:
 Indtroduced discount
********************************************************************************************************************************/

 v_IsProcessed VARCHAR(60);
 v_Canceled NUMERIC:=0;
 v_Generated NUMERIC:=0;
 v_Applied NUMERIC:=0;
 v_Settlement_ID VARCHAR(32); 
 v_Currency_ID VARCHAR(32); 
 v_S_Currency_ID VARCHAR(32); 
 v_S_Date  TIMESTAMP;
 v_Client_ID VARCHAR(32); 
 v_Org_ID VARCHAR(32); 
 v_multiplier NUMERIC:=1;
 v_Oldmultiplier NUMERIC:=1;
 v_Processed VARCHAR(60);
 v_Aux NUMERIC;

BEGIN

    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  /* Checking constraints */
  IF (TG_OP = 'DELETE') THEN
    IF (old.isValid = 'Y') THEN
      SELECT COALESCE(MAX(Processed),'Y') INTO v_Processed
      FROM C_Invoice
      WHERE C_Invoice_ID = old.C_Invoice_ID;
      --dbms_output.put_line('inv:'||coalesce(:old.C_Invoice_ID,'null') ||' ord:'|| coalesce(:old.C_Order_ID,'null'));
      IF (v_Processed = 'Y' AND NOT (old.C_Invoice_ID IS NULL AND old.C_Order_ID IS NOT NULL)) THEN
        -- SZ can be Revoked by Bankstatements. All manual interaction is disabled in the system
        --RAISE EXCEPTION '%', 'A valid Debt/Payment should not be deleted'; --OBTG:-20513--
      END IF;
    END IF;
  ELSIF (TG_OP = 'INSERT') THEN
    IF (new.C_Settlement_Generate_ID IS NOT NULL) THEN
      SELECT processed INTO v_IsProcessed
       FROM C_Settlement
       WHERE C_Settlement_ID =new.C_Settlement_Generate_ID;
      IF v_IsProcessed='Y' THEN
        RAISE EXCEPTION '%', '@settlementprocessed@:'||(SELECT documentno FROM C_Settlement WHERE C_Settlement_ID =new.C_Settlement_Generate_ID);
      END IF;
    END IF;

  IF (COALESCE(NEW.IsAutomaticGenerated,'Y')='N' AND NEW.C_Order_ID IS NOT NULL) THEN
      -- Check if it is totally invoiced
      SELECT COALESCE(SUM(NOTINVOICED),0)
        INTO v_Aux
        FROM (SELECT (O.QTYORDERED- COALESCE(LL.QTYINVOICED,0)) AS NOTINVOICED
                FROM C_ORDERLINE O LEFT JOIN (SELECT IL.C_INVOICELINE_ID, IL.QTYINVOICED, IL.C_ORDERLINE_ID
                                                FROM C_INVOICELINE IL,
                                                     C_INVOICE I
                                                WHERE IL.C_INVOICE_ID = I.C_INVOICE_ID
                                                  AND I.PROCESSED='Y') LL
                                                  ON LL.C_ORDERLINE_ID = O.C_ORDERLINE_ID
              WHERE O.C_ORDER_ID = NEW.C_Order_ID) AAA;
        IF v_Aux = 0 THEN
          select count(*)
            into v_Aux
            from c_orderline
           where c_order_id = NEW.C_Order_ID;
           if v_Aux>0 then
             RAISE EXCEPTION '%', '@OrderCompletelyInvoiced@'; --OBTG:-20000--
           end if;
        END IF;

      -- If Order is processed, DP should be valid
      SELECT PROCESSED
       INTO v_IsProcessed
        FROM C_ORDER
      WHERE C_ORDER_ID = NEW.C_Order_ID;
      IF v_IsProcessed = 'Y' THEN
         NEW.IsValid:='Y';
      END IF;
    END IF;

  IF (COALESCE(new.IsAutomaticGenerated,'Y')='N' AND new.C_Invoice_ID IS NOT NULL) THEN
      SELECT Processed
     INTO v_IsProcessed
     FROM C_Invoice
    WHERE C_Invoice_ID = new.C_Invoice_ID;
    IF v_IsProcessed = 'Y' THEN
      RAISE EXCEPTION '%', 'The invoice is processed'; --OBTG:-20508--
    END IF;
    END IF;
    new.Status := new.Status_Initial;
    -- On Invoices you can determin the Bank account of your Business-Partner. This is important for SAPA, though only Banaccounts with IBAN are suggested here.
    select c_bp_bankaccount_id into new.c_bp_bankaccount_id from c_bp_bankaccount where c_bpartner_id=new.c_bpartner_id and iban is not null and isactive='Y' order by mndtident limit 1;
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (old.IsValid = 'Y' AND ((old.IsActive <> new.IsActive)
                   OR (old.IsReceipt<>new.IsReceipt)
               OR (COALESCE(old.C_Settlement_Generate_ID,'0')<>COALESCE(new.C_Settlement_Generate_ID,'0'))
               -- OR (COALESCE(:old.C_Invoice_ID,'0')<>COALESCE(:new.C_Invoice_ID,'0'))
                OR (COALESCE(old.C_BPartner_ID,'0')<>COALESCE(new.C_BPartner_ID,'0'))
               OR (old.C_Currency_ID<>new.C_Currency_ID)
               OR (old.Amount<>new.Amount)
               OR (old.IsManual<>new.IsManual))) THEN
      RAISE EXCEPTION '%', 'A valid Debt/Payment should not be modified'; --OBTG:-20501--
    END IF;
    IF (C_DEBT_PAYMENT_STATUS(old.C_Settlement_Cancel_ID,old.Cancel_Processed,old.Generate_Processed,
        old.IsPaid,old.IsValid,old.C_CashLine_ID,old.C_BankStatementLine_ID) NOT IN ('P','I')
     AND ((COALESCE(old.C_BankAccount_ID,'0')<>COALESCE(new.C_BankAccount_ID,'0')) OR
       (COALESCE(old.C_CashBook_ID,'0')<>COALESCE(new.C_CashBook_ID,'0')) OR
        (old.PaymentRule<>new.PaymentRule) OR (old.DatePlanned<>new.DatePlanned))) THEN
      RAISE EXCEPTION '%', 'This Debt/Payment can not be modified'; --OBTG:-20511--
    END IF;
    IF (new.C_Settlement_Cancel_ID IS NOT NULL) THEN
     IF (old.C_Settlement_Cancel_ID<>new.C_Settlement_Cancel_ID) THEN
        RAISE EXCEPTION '%', '@DebtPaymentAlreadyInSettlementCancel@'; -- OBTG:-20512--
     END IF;
     IF ((COALESCE(old.C_Settlement_Cancel_ID,'0')<>COALESCE(new.C_Settlement_Cancel_ID,'0'))
      OR (old.IsPaid<>new.IsPaid)
      OR (old.WriteOffAmt<>new.WriteOffAmt)) THEN
          SELECT processed INTO v_IsProcessed FROM C_Settlement
          WHERE C_Settlement_ID =new.C_Settlement_Cancel_ID;

          IF v_IsProcessed='Y' THEN
           RAISE EXCEPTION '%', '@settlementprocessed@:'||(SELECT documentno FROM C_Settlement WHERE C_Settlement_ID =new.C_Settlement_Cancel_ID); --OBTG:-20510--
          END IF;
     END IF;
    END IF;
    IF (new.C_Settlement_Generate_ID IS NOT NULL) THEN
      IF ((old.C_GLItem_ID<>new.C_GLItem_ID)
        OR (old.IsDirectPosting<>new.IsDirectPosting)) THEN
        SELECT processed INTO v_IsProcessed FROM C_Settlement
          WHERE C_Settlement_ID =new.C_Settlement_Generate_ID;
          IF v_IsProcessed='Y' THEN
           RAISE EXCEPTION '%', '@settlementprocessed@:'||(SELECT documentno FROM C_Settlement WHERE C_Settlement_ID =new.C_Settlement_Generate_ID);
          END IF;
      END IF;
    END IF;
  END IF;
-- Avoid a bug when approving payments
-- No change in isapproved -> no change in updated and updatedby
IF(TG_OP = 'UPDATE') THEN
        if(
        -- no changes in record except updated or updatedby
        old.c_debt_payment_id = new.c_debt_payment_id and
        old.ad_client_id = new.ad_client_id and
        old.ad_org_id = new.ad_org_id and
        old.isactive = new.isactive and
        old.created = new.created and
        old.createdby = new.createdby and
        old.isreceipt = new.isreceipt and
        coalesce(old.c_settlement_cancel_id, '0') = coalesce(new.c_settlement_cancel_id, '0') and
        coalesce(old.c_settlement_generate_id, '0') = coalesce(new.c_settlement_generate_id, '0') and
        coalesce(old.description, '0') = coalesce(new.description, '0') and
        coalesce(old.c_invoice_id, '0') = coalesce(new.c_invoice_id, '0') and   
        coalesce(old.c_bpartner_id, '0') = coalesce(new.c_bpartner_id, '0') and
        old.c_currency_id = new.c_currency_id and
        coalesce(old.c_cashline_id, '0') = coalesce(new.c_cashline_id, '0') and
        coalesce(old.c_bankaccount_id, '0') = coalesce(new.c_bankaccount_id, '0') and
        coalesce(old.c_cashbook_id, '0') = coalesce(new.c_cashbook_id, '0') and
        old.paymentrule = new.paymentrule and
        old.ispaid = new.ispaid and
        old.amount = new.amount and
        coalesce(old.writeoffamt, '0') = coalesce(new.writeoffamt, '0') and
        old.dateplanned = new.dateplanned and
        old.ismanual = new.ismanual and
        old.isvalid = new.isvalid and
        coalesce(old.c_bankstatementline_id, '0') = coalesce(new.c_bankstatementline_id, '0') and
        old.changesettlementcancel = new.changesettlementcancel and
        old.cancel_processed = new.cancel_processed and
        old.generate_processed = new.generate_processed and
        coalesce(old.glitemamt, '0') = coalesce(new.glitemamt, '0') and
        old.isdirectposting = new.isdirectposting and
        coalesce(old.c_glitem_id, '0') = coalesce(new.c_glitem_id, '0') and
        coalesce(old.c_order_id, '0') = coalesce(new.c_order_id, '0') and
        coalesce(old.c_project_id, '0') = coalesce(new.c_project_id, '0') and
        coalesce(old.isautomaticgenerated, '0') = coalesce(new.isautomaticgenerated, '0') and   
        old.status = new.status and
        coalesce(old.status_initial, '0') = coalesce(new.status_initial, '0') and
        coalesce(old.c_withholding_id, '0') = coalesce(new.c_withholding_id, '0') and
        coalesce(old.withholdingamount, '0') = coalesce(new.withholdingamount, '0') and
        coalesce(old.discountamt, '0') = coalesce(new.discountamt, '0') and
        old.isapproved = new.isapproved and
        -- no changes in record except updated or updatedby
        (old.updated <> new.updated or
        old.updatedby <> new.updatedby)
        ) then
                -- discard changes
                new.updated := old.updated;
                new.updatedby := old.updatedby;
        END IF;
END IF;
  /*************************************************************************
    * SZ: Introduced Discount
    ************************************************************************/
  /**
  * Calculate amounts for Settlements
  */
  IF (TG_OP = 'DELETE') THEN
    IF (old.C_Settlement_Generate_ID IS NOT NULL AND old.Generate_Processed = 'N') THEN
   IF (old.IsReceipt = 'N') THEN
     v_multiplier := -1;
  END IF;
      v_Generated := (- COALESCE(old.Amount, 0))*v_multiplier;
  IF (old.IsPaid = 'Y') THEN
     v_Applied := (COALESCE(old.Amount, 0) - COALESCE(old.WriteOffAmt, 0)- COALESCE(old.discountamt, 0))*v_multiplier;
  END IF;
  v_Settlement_ID := old.C_Settlement_Generate_ID;
  v_Currency_ID := old.C_Currency_ID;
    END IF;
  END IF;
  IF (TG_OP = 'UPDATE') THEN
    IF (new.Ad_Org_Id!=old.ad_Org_ID) and (NEW.C_Invoice_ID is not null) THEN
     SELECT Processed
         INTO v_IsProcessed
         FROM C_Invoice
        WHERE C_Invoice_ID = new.C_Invoice_ID;
        IF v_IsProcessed = 'Y' THEN
          RAISE EXCEPTION '%', 'The invoice is processed'; --OBTG:-20508--
        END IF;
    END IF;

     IF (old.C_Settlement_Generate_ID IS NOT NULL AND old.Generate_Processed = 'N'
    AND new.Generate_Processed = 'N')
   THEN
   IF (old.IsReceipt = 'N') THEN
    v_Oldmultiplier := -1;
   END IF;
  IF (new.IsReceipt = 'N') THEN
      v_multiplier := -1;
  END IF;
    v_Generated := v_Generated - (COALESCE(old.Amount, 0)*v_Oldmultiplier);
  IF (old.IsPaid = 'Y') THEN
      v_Applied := COALESCE(v_Applied, 0) - (COALESCE(old.Amount, 0) - COALESCE(old.WriteOffAmt, 0)- COALESCE(old.discountamt, 0))*v_Oldmultiplier;
  END IF;
     v_Generated := v_Generated + (COALESCE(new.Amount, 0)*v_multiplier);
  IF (new.IsPaid = 'Y') THEN
      v_Applied := COALESCE(v_Applied,0) + (COALESCE(new.Amount,0) - COALESCE(new.WriteOffAmt,0)- COALESCE(new.discountamt, 0))*v_multiplier;
  END IF;
  v_Settlement_ID := new.C_Settlement_Generate_ID;
  v_Currency_ID := new.C_Currency_ID;
    END IF;
    IF (old.C_Settlement_Cancel_ID IS NOT NULL AND old.Cancel_Processed = 'N' AND new.Cancel_Processed = 'N') THEN
   IF (old.IsReceipt = 'N') THEN
    v_multiplier := -1;
   END IF;
   IF (old.IsPaid = 'Y') THEN
    v_Applied := COALESCE(v_Applied,0) - (COALESCE(old.Amount,0) - COALESCE(old.WriteOffAmt,0)- COALESCE(old.discountamt, 0))*v_multiplier;
   ELSE
    v_Canceled := COALESCE(v_Canceled,0) - (COALESCE(old.Amount,0) - COALESCE(old.WriteOffAmt,0)- COALESCE(old.discountamt, 0))*v_multiplier;
   END IF;
   v_Settlement_ID := old.C_Settlement_Cancel_ID;
   v_Currency_ID := old.C_Currency_ID;
  END IF;
  IF (new.C_Settlement_Cancel_ID IS NOT NULL AND old.Cancel_Processed = 'N' AND new.Cancel_Processed = 'N') THEN
   IF (new.IsReceipt = 'N') THEN
    v_multiplier := -1;
   END IF;
   IF (new.IsPaid = 'Y') THEN
    v_Applied := COALESCE(v_Applied,0) + (COALESCE(new.Amount,0) - COALESCE(new.WriteOffAmt,0)- COALESCE(new.discountamt, 0))*v_multiplier;
   ELSE
    v_Canceled := COALESCE(v_Canceled,0) + (COALESCE(new.Amount,0) - COALESCE(new.WriteOffAmt,0)- COALESCE(new.discountamt, 0))*v_multiplier;
   END IF;
   v_Settlement_ID := new.C_Settlement_Cancel_ID;
   v_Currency_ID := new.C_Currency_ID;
  END IF;
 END IF;
  IF (TG_OP = 'INSERT') THEN
    IF (new.C_Settlement_Generate_ID IS NOT NULL AND new.Generate_Processed = 'N') THEN
   IF (new.IsReceipt = 'N') THEN
    v_multiplier := -1;
   END IF;
   v_Generated := COALESCE(new.Amount,0)*v_multiplier;
   IF (new.IsPaid = 'Y') THEN
    v_Applied := COALESCE(v_Applied,0) + (COALESCE(new.Amount,0) - COALESCE(new.WriteOffAmt,0)- COALESCE(new.discountamt, 0))*v_multiplier;
   END IF;
   v_Settlement_ID := new.C_Settlement_Generate_ID;
   v_Currency_ID := new.C_Currency_ID;
    END IF;
  END IF;
  IF (v_Settlement_ID IS NOT NULL) THEN
    SELECT C_Currency_ID, DateTrx, AD_Client_ID, AD_Org_ID
  INTO v_S_Currency_ID, v_S_Date, v_Client_ID, v_Org_ID
  FROM C_Settlement WHERE C_Settlement_ID = v_Settlement_ID;

  IF (v_Currency_ID <> v_S_Currency_ID) THEN
   v_Canceled :=C_Currency_Convert(v_Canceled, v_Currency_ID, v_S_Currency_ID, v_S_Date, null, v_Client_ID, v_Org_ID);
   v_Generated := C_Currency_Convert(v_Generated, v_Currency_ID, v_S_Currency_ID, v_S_Date, null, v_Client_ID, v_Org_ID);
   v_Applied :=C_Currency_Convert(v_Applied, v_Currency_ID, v_S_Currency_ID, v_S_Date, null, v_Client_ID, v_Org_ID);
  END IF;
  -- Update header
    UPDATE C_Settlement
    SET CanceledNotChargeAmt = COALESCE(CanceledNotChargeAmt, 0) + COALESCE(v_Canceled, 0),
  GeneratedAmt = COALESCE(GeneratedAmt, 0) + COALESCE(v_Generated, 0),
  ChargedAmt = COALESCE(ChargedAmt, 0) + COALESCE(v_Applied, 0)
    WHERE C_Settlement_ID = v_Settlement_ID;
 END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION c_debt_payment_trg() OWNER TO tad;








-- Function: c_bankstatement_post(character varying)

-- DROP FUNCTION c_bankstatement_post(character varying);

CREATE OR REPLACE FUNCTION c_bankstatement_post(p_pinstance_id character varying)
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

/* Contributions:
 Indtroduced discount
 Removed DP-Management
 Reorganized Code
 Issue 448: Automatic Creation-Cancellation of Settlemets on BStmts. Payment-Monitor Updates. Header Updates corrected
********************************************************************************************************************************/
  -- Logistice
  v_ResultStr VARCHAR(2000):=''; 
  v_Result NUMERIC;
  v_Message VARCHAR(2000):=''; 
  v_Record_ID VARCHAR(32); 
  v_User VARCHAR(32); 
  v_DPManagementDocType_ID VARCHAR(32); 
  v_DPMId VARCHAR(32); --OBTG:varchar2--
  v_DPMLineId VARCHAR(32); --OBTG:varchar2--
   --Added by P.SAROBE
    v_C_Debt_Payment_ID VARCHAR(32); 
    v_documentno_Settlement VARCHAR; 
    v_documentno_Dp_Management VARCHAR; 
    v_column_identifier VARCHAR(200); 
    v_dateSettlement TIMESTAMP;
    v_Cancel_Processed VARCHAR(60);
    v_nameBankstatement VARCHAR; 
    v_dateBankstatement TIMESTAMP;
    v_nameCash VARCHAR; 
    v_dateCash TIMESTAMP;
    v_Bankstatementline_ID VARCHAR(32); 
    v_CashLine_ID VARCHAR(32); 
    v_Settlement_Cancel_ID VARCHAR(32); 
    v_ispaid CHAR(1);
    v_is_included NUMERIC:=0;
    v_available_period NUMERIC:=0;
    v_is_ready AD_Org.IsReady%TYPE;
    v_is_tr_allow AD_OrgType.IsTransactionsAllowed%TYPE;
    v_isacctle AD_OrgType.IsAcctLegalEntity%TYPE;
    v_org_bule_id AD_Org.AD_Org_ID%TYPE;
    --Finish added by P.Sarobe
  -- Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    Cur_BankstatementDebtpayment RECORD;
    -- Parameter Variables
    --  Parameter Variables
    v_Processed CHAR(1) ;
                v_Posted CHAR(1) ;
                v_Processing CHAR(1) ;
    v_count NUMERIC;
    v_SettlementDocType_ID VARCHAR(32) ; 
    v_settlementID VARCHAR(32) ; --OBTG:varchar2--
    v_DocumentNo VARCHAR(50); 
    v_line C_CASHLINE.LINE%TYPE;
    -- BankAccount
    v_BA_Currency_ID VARCHAR(32) ; 
    v_BS_Date TIMESTAMP;
    v_AD_Org_ID VARCHAR(32); 
    v_AD_Client_ID VARCHAR(32) ; 
    FINISH_PROCESS BOOLEAN:=false;
    v_sepastatus varchar; -- 'Y' SEpa verarbeitet, 'R' SEPA Zurücknehmen, 'P' SEPA verarbeiten, 'N' Normaler Bankabgleich, kein SEPA
    v_nopinstance varchar:='N';
    v_invoice varchar;
    Cur_AutomaticSettlementCancel RECORD;
    CUR_MANAGEMENTLINES RECORD;
    v_DP_MANAGEMENT NUMERIC;
    v_DATEACCT TIMESTAMP;
    v_DATETRX TIMESTAMP;
    v_Total NUMERIC:=0;
    v_Currency_ID VARCHAR(32):=NULL; 
    -- Lines
    Cur_Lines RECORD;
    CUR_BSLINES_DATES RECORD;
    Cur_ManagementLines1 RECORD;
    v_cur record;
    v_cur2 record;
    v_bstupdated timestamp without time zone;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    if v_Record_ID is null or (select count(*) from c_bankstatement where c_bankstatement_id=p_PInstance_ID)>0 then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       select updatedby into v_user from c_bankstatement where  c_bankstatement_id=v_Record_ID;
       v_nopinstance:='Y';
    end if;
    SELECT PROCESSED,sepacollectioniscreated,
      POSTED,PROCESSING,      AD_Client_ID,      AD_Org_ID
    INTO v_Processed,v_sepastatus,
      v_Posted,                 v_Processing,      v_AD_Client_ID,      v_AD_Org_ID
    FROM C_BANKSTATEMENT
    WHERE C_BankStatement_ID=v_Record_ID
    FOR UPDATE;
                IF(v_Processing='Y') THEN
                RAISE EXCEPTION '%', '@OtherProcessActive@' ; --OBTG:-20000--
                END IF;
                IF(v_Posted='Y') THEN
                RAISE EXCEPTION '%', '@BankStatementDocumentPosted@' ; --OBTG:-20000--
                END IF;
    -- Set Sepa Processed
    /*
    -- The following code is creating a settlenment before the real bank transaction is done
    -- It was deactivated , we create Settlement when the real transaction against Bank is done
    if v_sepastatus='Y' and v_Processed = 'N' then 
        UPDATE C_BANKSTATEMENT
        SET processed='Y'
        WHERE C_BANKSTATEMENT_ID = v_Record_ID;
        -- Call User Exit Function
        select  c_bankstatement_post_userexit(v_Record_ID) into v_message;
        PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, v_User, 'N', 1, 'SEPA Bankstatement Processed'||v_message) ;
        RETURN;
    end if;
    */
    UPDATE C_BANKSTATEMENT
    SET PROCESSING='Y'
    WHERE C_BANKSTATEMENT_ID = v_Record_ID;
    /*
     *  Functional Body
    */
      -- Check if there are lines document does
      if (select count(*) from  C_BANKSTATEMENTLINE where C_BANKSTATEMENT_id=V_Record_ID)=0 then
          RAISE EXCEPTION '%', '@NoLinesInDoc_c_bankstatement_post@';
      END IF;
      /*
      *  Reversing process
      */
      IF (v_Processed = 'Y') THEN
        -- OR (v_Processed = 'N' and v_sepastatus='R')) THEN
        --settlenment before the real bank transaction is done / Deactivated
        v_ResultStr := 'Reversed';
        -- Vorherige Bankabgleiche? - Nur der jeweils letzte Bankabgleich kann zurückgenommen werden.
        for v_cur in (select * from c_bankstatementline where c_bankstatement_id=V_Record_ID)
        LOOP
            select updated into v_bstupdated from c_debt_payment where c_bankstatementline_id=v_cur.c_bankstatementline_id;
            for v_cur2 in (select * from c_debt_payment where c_invoice_id = (select c_invoice_id from c_debt_payment where c_debt_payment_id=v_cur.c_debt_payment_id) and c_bankstatementline_id is not null
                           and c_bankstatementline_id!=v_cur.c_bankstatementline_id)
            LOOP                
                if v_bstupdated<v_cur2.updated then
                    RAISE EXCEPTION '%', '@bankstatementprocessed@:'||(SELECT b.name FROM C_bankstatement b,c_bankstatementline l WHERE b.C_bankstatement_ID =l.C_bankstatement_ID and l.c_bankstatementline_id = v_cur2.c_bankstatementline_id);
                end if;
            END LOOP;
        END LOOP;
        --Unpost Settlement
        FOR Cur_AutomaticSettlementCancel IN (SELECT DISTINCT S.C_SETTLEMENT_ID
              FROM C_DEBT_PAYMENT DP, C_SETTLEMENT S
              WHERE DP.C_SETTLEMENT_CANCEL_ID = S.C_SETTLEMENT_ID
              AND DP.C_BANKSTATEMENTLINE_ID IN
                  (SELECT C_BANKSTATEMENTLINE_ID FROM C_BANKSTATEMENTLINE
                  WHERE C_BANKSTATEMENT_ID = v_Record_ID)
                    AND S.DOCUMENTNO LIKE '*BSP*%') 
        LOOP
          -- Reset fact acct
          DELETE FROM FACT_ACCT WHERE AD_TABLE_ID = '800019' AND RECORD_ID = Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
          UPDATE C_SETTLEMENT SET POSTED='N',PROCESSED='N' WHERE C_SETTLEMENT_ID = Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
          
          UPDATE C_DEBT_PAYMENT
          SET  C_BANKSTATEMENTLINE_ID = NULL, ISPAID = 'N', CANCEL_PROCESSED = 'N'
          WHERE C_SETTLEMENT_CANCEL_ID = Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
          -- Update Invoice Header
          perform zsfi_paymentmonitor(Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID);
          UPDATE C_DEBT_PAYMENT SET C_SETTLEMENT_CANCEL_ID = NULL WHERE C_SETTLEMENT_CANCEL_ID = Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
          -- Usually SETTLEMENT is Posted, and this Function doesn't perform Unpost -- After this Usually  a rollback Follows
          -- SZ : Issue 405 solved.
          --PERFORM C_SETTLEMENT_POST(null, Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID);
          DELETE FROM C_SETTLEMENT WHERE C_SETTLEMENT_ID = Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
        END LOOP;

   --SZ Delete DP_Mamagement
    --FOR CUR_MANAGEMENTLINES IN (SELECT  BSL.C_DP_MANAGEMENT_ID, RL.C_REMITTANCELINE_ID, BSL.C_BANKSTATEMENTLINE_ID, BSL.LINE
         UPDATE C_DEBT_PAYMENT SET C_BANKSTATEMENTLINE_ID = NULL
          WHERE C_BANKSTATEMENTLINE_ID IS NOT NULL
            AND C_BANKSTATEMENTLINE_ID IN
                                        (SELECT C_BANKSTATEMENTLINE_ID FROM C_BANKSTATEMENTLINE
                                          WHERE C_BANKSTATEMENT_ID = v_Record_ID);
          -- UN Post eventually Created automatic settlements belonging to this bankstatement
          for Cur_AutomaticSettlementCancel in (select c_settlement_id from c_settlement where processed='Y' and bankstatementline in (select c_bankstatementline_id from c_bankstatementline where c_bankstatement_id=v_Record_ID)
                                      order by documentno)
          LOOP
             DELETE FROM FACT_ACCT WHERE AD_TABLE_ID = '800019' AND RECORD_ID = Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
             UPDATE C_DEBT_PAYMENT set  ISPAID = 'N', CANCEL_PROCESSED = 'N' where c_settlement_generate_id=Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
             UPDATE C_DEBT_PAYMENT set  ISPAID = 'N', CANCEL_PROCESSED = 'N' where c_settlement_cancel_id=Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
             UPDATE C_SETTLEMENT SET POSTED='N',PROCESSED='N' WHERE C_SETTLEMENT_ID = Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID;
             -- Update Invoice Header
             perform zsfi_paymentmonitor(Cur_AutomaticSettlementCancel.C_SETTLEMENT_ID);
          END LOOP;
          UPDATE C_BANKSTATEMENT
             SET PROCESSED = 'N',
                 PROCESSING = 'N',
                 sepacollectioniscreated ='N'
          WHERE C_BANKSTATEMENT_ID = v_Record_ID;
          FINISH_PROCESS := true;
       END IF;   
    IF(NOT FINISH_PROCESS) THEN
      /*
      *  Checking Restrictions
      */
      -- Check the header belongs to a organization where transactions are posible and ready to use
      SELECT AD_Org.IsReady, Ad_OrgType.IsTransactionsAllowed
      INTO v_is_ready, v_is_tr_allow
      FROM C_BANKSTATEMENT, AD_Org, AD_OrgType
      WHERE AD_Org.AD_Org_ID=C_BANKSTATEMENT.AD_Org_ID
            AND AD_Org.AD_OrgType_ID=AD_OrgType.AD_OrgType_ID
            AND C_BANKSTATEMENT.C_BANKSTATEMENT_ID=v_Record_ID;
      IF (v_is_ready='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotReady@'; --OBTG:-20000--
      END IF;
      IF (v_is_tr_allow='N') THEN
        RAISE EXCEPTION '%', '@OrgHeaderNotTransAllowed@'; --OBTG:-20000--
      END IF;

      SELECT AD_ORG_CHK_DOCUMENTS('C_BANKSTATEMENT', 'C_BANKSTATEMENTLINE', v_Record_ID, 'C_BANKSTATEMENT_ID', 'C_BANKSTATEMENT_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@LinesAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;

      SELECT AD_ORG_CHK_DOC_PAYMENTS('C_BANKSTATEMENT', 'C_BANKSTATEMENTLINE', v_Record_ID, 'C_BANKSTATEMENT_ID', 'C_BANKSTATEMENT_ID', 'C_DEBT_PAYMENT_ID') INTO v_is_included FROM dual;
      IF (v_is_included=-1) THEN
        RAISE EXCEPTION '%', '@PaymentsAndHeaderDifferentLEorBU@'; --OBTG:-20000--
      END IF;

      -- Check the period control is opened (only if it is legal entity with accounting)
      SELECT StatementDate
      INTO v_BS_Date
      FROM C_BankStatement
      WHERE C_BankStatement_ID=v_Record_ID;

      -- Gets the BU or LE of the document
      SELECT AD_GET_DOC_LE_BU('C_BANKSTATEMENT', v_Record_ID, 'C_BANKSTATEMENT_ID', 'LE')
      INTO v_org_bule_id
      FROM DUAL;

      SELECT AD_OrgType.IsAcctLegalEntity
      INTO v_isacctle
      FROM AD_OrgType, AD_Org
      WHERE AD_Org.AD_OrgType_ID = AD_OrgType.AD_OrgType_ID
      AND AD_Org.AD_Org_ID=v_org_bule_id;

      IF (v_isacctle='Y') THEN
        SELECT C_CHK_OPEN_PERIOD(v_AD_Org_ID, v_BS_Date, 'CMB', NULL)
        INTO v_available_period
        FROM DUAL;

        IF (v_available_period<>1) THEN
          RAISE EXCEPTION '%', '@PeriodNotAvailable@'; --OBTG:-20000--
        END IF;
      END IF;


      v_ResultStr:='CheckingRestrictions - C_BANKSTATEMENT ORG IS IN C_BANKACCOUNT ORG TREE';
      SELECT COUNT(*)
      INTO v_count
      FROM C_BANKSTATEMENT c,
        C_BANKACCOUNT b
      WHERE c.C_BankStatement_ID=v_Record_ID
        AND c.C_BANKACCOUNT_ID=b.C_BANKACCOUNT_ID
        AND Ad_Isorgincluded(c.AD_ORG_ID, b.AD_ORG_ID, b.AD_CLIENT_ID)=-1;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@NotCorrectOrgBankaccount@' ; --OBTG:-20000--
      END IF;
   
      v_ResultStr:='CheckingRestrictions - C_BANKSTATEMENT ORG IS IN C_DEBT_PAYMENT ORG TREE';
      /*
      *  Checking Restrictions
      */
      --Added by PSarobe. Same way as C_CASH_POST
      SELECT COUNT(*),
        MAX(cl.Line)
      INTO v_count,
        v_line
      FROM C_BANKSTATEMENT c,
        C_BANKSTATEMENTLINE cl,
        C_DEBT_PAYMENT l,
        C_BPARTNER bp
      WHERE c.C_BANKSTATEMENT_ID=cl.C_BANKSTATEMENT_ID
        AND c.C_BANKSTATEMENT_ID=v_Record_ID
        AND cl.C_DEBT_PAYMENT_ID=l.C_DEBT_PAYMENT_ID
        AND l.C_BPARTNER_ID=bp.C_BPARTNER_ID
        AND(Ad_Isorgincluded(l.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1--To be deprecated, to be fixed. This Check restriction should be checked when debt payment is created. Added by PSarobe
        OR Ad_Isorgincluded(l.AD_ORG_ID, c.AD_ORG_ID, c.AD_CLIENT_ID)=-1) ;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@NotCorrectOrgDebtpaymentBankstatement@' ; --OBTG:-20000--
      END IF;--Finish added by PSarobe
      /*
      *  Checking Restrictions
      *  SZ added discount
      */
      SELECT COUNT(*),
        MAX(bsl.Line)
      INTO v_count,
        v_line
      FROM C_BANKSTATEMENTLINE bsl,
        C_DEBT_PAYMENT dp
      WHERE bsl.C_BankStatement_ID=v_Record_ID
        AND bsl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        AND bsl.C_Currency_ID=dp.C_Currency_ID
        AND CASE dp.IsReceipt WHEN 'Y' THEN -- If IsReceipt = N, amount*-1
            (dp.Amount-coalesce(dp.WriteOffAmt,0)-coalesce(dp.discountamt,0)) ELSE(coalesce(dp.WriteOffAmt,0)+coalesce(dp.discountamt,0)-dp.Amount)
        END <>(bsl.TrxAmt) ;
      IF v_count>0 THEN
       RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@DebtAmountsSamemoneyNoMatch@' ; --OBTG:-20000--
      END IF;
      /*
      *  Checking Restrictions
      *  SZ added discount
      */
      SELECT COUNT(*),
        MAX(bsl.Line)
      INTO v_count,
        v_line
      FROM C_BANKSTATEMENTLINE bsl,
        C_BANKSTATEMENT bs,
        C_DEBT_PAYMENT dp
      WHERE bsl.C_BankStatement_ID=bs.C_BankStatement_ID
        AND bsl.C_BankStatement_ID=v_Record_ID
        AND bsl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        AND bsl.C_Currency_ID<>dp.C_Currency_ID
        AND
        CASE dp.IsReceipt WHEN 'Y' THEN -- If IsReceipt = N, amount*-1
          (dp.Amount-coalesce(dp.WriteOffAmt,0)-coalesce(dp.discountamt,0)) ELSE(coalesce(dp.WriteOffAmt,0)+coalesce(dp.discountamt,0)-dp.Amount)
        END
        <> bsl.foreigncurrencyamt;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@DebtAmountsDifferentMoneyNoMatch@' ; --OBTG:-20000--
      END IF;
      /*
      *  Checking Restrictions
      */
      SELECT COUNT(*), MAX(bsl.C_BANKSTATEMENTLINE_ID)
      INTO v_count, v_Bankstatementline_ID
      FROM C_BANKSTATEMENTLINE bsl,C_DEBT_PAYMENT dp
      WHERE bsl.C_BankStatement_ID=v_Record_ID
        AND bsl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
        AND C_Debt_Payment_Status(dp.C_SETTLEMENT_CANCEL_ID, dp.Cancel_Processed, dp.Generate_Processed, dp.IsPaid, dp.IsValid, dp.C_CashLine_ID, dp.C_BankStatementLine_ID) NOT IN('P', 'A') ;
      IF v_count>0 THEN
        --Added by P.Sarobe. New messages
        -- SZ? -> Chacks if already exists a bankstatement for this line??? (Schould not be possible??)
        SELECT line, c_Debt_payment_Id INTO v_line, v_C_Debt_Payment_Id
        FROM C_Bankstatementline WHERE c_Bankstatementline_Id = v_Bankstatementline_ID;

        SELECT c_Bankstatementline_Id, c_cashline_id, c_settlement_cancel_id, ispaid, cancel_processed
        INTO v_Bankstatementline_ID, v_CashLine_ID, v_Settlement_Cancel_ID, v_ispaid, v_Cancel_Processed
        FROM C_DEBT_PAYMENT WHERE C_Debt_Payment_ID = v_C_Debt_Payment_Id;

        IF v_Bankstatementline_ID IS NOT NULL THEN
            SELECT C_BANKSTATEMENT.NAME, C_BANKSTATEMENT.STATEMENTDATE
            INTO v_nameBankstatement, v_dateBankstatement
            FROM C_BANKSTATEMENT, C_BANKSTATEMENTLINE
            WHERE C_BANKSTATEMENT.C_BANKSTATEMENT_ID = C_BANKSTATEMENTLINE.C_BANKSTATEMENT_ID
            AND C_BANKSTATEMENTLINE.C_BANKSTATEMENTLINE_ID = v_Bankstatementline_ID;
                    RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@ManagedDebtPaymentBank@'||v_nameBankstatement||' '||'@Bydate@'||v_dateBankstatement ; --OBTG:-20000--
        END IF;
        IF v_CashLine_ID IS NOT NULL THEN--This is also checked in the unique index C_CASHLINE_DEBT_PAYMENT
            SELECT C_CASH.NAME, C_CASH.STATEMENTDATE
            INTO v_nameCash, v_dateCash
            FROM C_CASH, C_CASHLINE
            WHERE C_CASH.C_CASH_ID = C_CASHLINE.C_CASH_ID
            AND C_CASHLINE.C_CASHLINE_ID = v_CashLine_ID;
            RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@ManagedDebtPaymentCash@'||v_nameCash||' '||'@Bydate@'||v_dateCash ; --OBTG:-20000--
        END IF;
        IF v_Cancel_Processed='Y' AND v_ispaid='N' THEN
            SELECT documentno, datetrx
            INTO v_documentno_Settlement, v_dateSettlement
            FROM C_SETTLEMENT
            WHERE C_SETTLEMENT_ID = v_Settlement_Cancel_ID;
            RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@ManagedDebtPaymentCancel@'||v_documentno_Settlement||' '||'@Bydate@'||v_dateSettlement ; --OBTG:-20000--
        END IF;
      END IF;  -- vCount    
       /*
      *  Checking Restrictions
      */
      SELECT COUNT(*), MAX(debtpayment_Id)
      INTO v_count, v_C_Debt_Payment_Id
      FROM
         (SELECT min(dp.C_Debt_Payment_ID) as debtpayment_Id
          FROM C_BANKSTATEMENTLINE bsl,C_DEBT_PAYMENT dp
          WHERE bsl.C_BankStatement_ID=v_Record_ID
             AND bsl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
          GROUP BY dp.C_Debt_Payment_ID
          HAVING COUNT(*)>1) A;
      IF v_count>0 THEN
        --Added by PSarobe.
        FOR Cur_BankstatementDebtpayment IN (SELECT line
             FROM c_Bankstatementline
             WHERE c_Bankstatementline.c_Bankstatement_id=v_Record_ID
                   AND c_Bankstatementline.c_debt_payment_id=v_C_Debt_Payment_Id
             ORDER BY line) LOOP
             v_Message:=v_Message||Cur_BankstatementDebtpayment.line||', ';
        END LOOP;
        RAISE EXCEPTION '%', '@Inlines@'||v_Message||' '||'@Samedebtpayment@' ; --OBTG:-20000--
      END IF;
    
      /*
      *  
      *  END RESTRICTIONS
      *******************************************************************************************************+++
      */
      
      /**
      *  Generate C_Settlement
      */
       /* Map error NUMERIC returned by raise_application_error to user-defined exception. */
       -- SZ Removed DP-Management
        -- Post eventually Created automatic settlements belonging to this bankstatement
        for Cur_ManagementLines1 in (select c_settlement_id from c_settlement where processed='N' and bankstatementline in (select c_bankstatementline_id from c_bankstatementline where c_bankstatement_id=v_Record_ID))
        LOOP
           PERFORM C_SETTLEMENT_POST(NULL,Cur_ManagementLines1.c_settlement_id);
        END LOOP;
        v_ResultStr:='GettingBankAccountInfo';
        SELECT ba.C_Currency_ID, bs.StatementDate
        INTO v_BA_Currency_ID,v_BS_Date
        FROM C_BANKACCOUNT ba,C_BANKSTATEMENT bs
        WHERE ba.C_BankAccount_ID=bs.C_BankAccount_ID
          AND bs.C_BankStatement_ID=v_Record_ID;
        v_SettlementDocType_ID:=Ad_Get_DocType(v_AD_Client_ID, v_AD_Org_ID, 'STT') ;
        FOR CUR_BSLINES_DATES IN
              (SELECT DISTINCT bsl.DATEACCT  as DATEACCT
              FROM C_BANKSTATEMENTLINE bsl,C_DEBT_PAYMENT dp
              WHERE bsl.C_BankStatement_ID=v_Record_ID
                AND bsl.C_Debt_Payment_ID=dp.C_Debt_Payment_ID
                AND C_Debt_Payment_Status(dp.C_SETTLEMENT_CANCEL_ID, dp.Cancel_Processed, dp.Generate_Processed, dp.IsPaid, dp.IsValid, dp.C_CashLine_ID, dp.C_BankStatementLine_ID)='P'
              )
        LOOP
          SELECT * INTO  v_settlementID FROM Ad_Sequence_Next('C_Settlement', v_Record_ID) ;
          SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doctype(v_SettlementDocType_ID, v_AD_Org_ID, 'Y') ;
          IF(v_DocumentNo IS NULL) THEN
            SELECT * INTO  v_DocumentNo FROM Ad_Sequence_Doc('DocumentNo_C_Settlement', v_AD_Org_ID, 'Y') ;
          END IF;
          /**
           *  Create the new settlement
           */
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
          SELECT v_settlementID,AD_Client_ID, AD_Org_ID, 'Y', TO_DATE(NOW()),
            UpdatedBy, TO_DATE(NOW()), UpdatedBy, '*BSP*'||v_DocumentNo, TRUNC(v_BS_Date),
            CUR_BSLINES_DATES.DATEACCT, 'B', v_SettlementDocType_ID, 'N',
            'N', 'N', v_BA_Currency_ID, NULL,
            NULL, NULL, NULL, NULL,
            'N', 'Y'
          FROM C_BANKSTATEMENT
          WHERE C_BankStatement_ID=v_Record_ID;
          /**
           *  Update the Payment
           */
          UPDATE C_DEBT_PAYMENT
            SET C_SETTLEMENT_CANCEL_ID=v_settlementID,
            IsPaid='Y'
          WHERE C_DEBT_PAYMENT.C_Debt_Payment_ID IN
            (SELECT C_Debt_Payment_ID FROM C_BANKSTATEMENTLINE
              WHERE C_BankStatement_ID=v_Record_ID AND  DateAcct=CUR_BSLINES_DATES.DATEACCT 
            )
            AND C_Debt_Payment_Status(C_DEBT_PAYMENT.C_SETTLEMENT_CANCEL_ID, C_DEBT_PAYMENT.Cancel_Processed, C_DEBT_PAYMENT.Generate_Processed, C_DEBT_PAYMENT.IsPaid, C_DEBT_PAYMENT.IsValid, C_DEBT_PAYMENT.C_CashLine_ID, C_DEBT_PAYMENT.C_BankStatementLine_ID)='P';
          /**
           *  Post the new settlement
           */
          PERFORM C_SETTLEMENT_POST(NULL, v_settlementID) ;
        END LOOP;
      /**
      *  Update Balances + De-Activate + Conciliate Debt_Payments
      */
        -- Calculate Total
        FOR Cur_Lines IN
          (SELECT * FROM C_BANKSTATEMENTLINE WHERE C_BankStatement_ID=v_Record_ID)
        LOOP
          v_ResultStr:='GettingTrxCurrency';
          -- Get Debt_Payment Currency and conciliate Debt/Payments
          IF(Cur_Lines.C_Debt_Payment_ID IS NOT NULL) THEN
            UPDATE C_DEBT_PAYMENT
              SET C_BankStatementLine_ID=Cur_Lines.C_BankStatementLine_ID
            WHERE C_Debt_Payment_ID=Cur_Lines.C_Debt_Payment_ID;   
            select c_invoice_id into v_invoice from C_DEBT_PAYMENT WHERE C_Debt_Payment_ID=Cur_Lines.C_Debt_Payment_ID;   
            update c_invoice set transactiondate=Cur_Lines.valutadate where c_invoice_id=v_invoice;
            select c_order_id into v_invoice from c_invoice where c_invoice_id=v_invoice;
            update c_order set transactiondate=Cur_Lines.valutadate where c_order_id=v_invoice;
          END IF;
          v_Total:=v_Total + Cur_Lines.trxAmt + Cur_Lines.chargeamt;
        END LOOP;
        --
        RAISE NOTICE '%','BankStatement Complete - Total=' || v_Total ;
        v_ResultStr:='UpdatingRecord';
       -- if v_sepastatus='N' then
            UPDATE C_BANKSTATEMENT
            SET StatementDifference=v_Total,
            EndingBalance=v_Total,
            Processed='Y',
            Updated=TO_DATE(NOW()),
            Processing='N'
            WHERE C_BankStatement_ID=v_Record_ID;
        -- The following code is creating a settlenment before the real bank transaction is done
        -- It was deactivated , we create Settlement when the real transaction against Bank is done
        --else --sepastatus='P'
        --    UPDATE C_BANKSTATEMENT
        --    SET StatementDifference=v_Total,
        --    EndingBalance=v_Total,
        --    sepacollectioniscreated='Y',
        --    Updated=TO_DATE(NOW()),
        --    Processing='N'
        --   WHERE C_BankStatement_ID=v_Record_ID;
        --end if;
    END IF;--FINISH_PROCESS
    -- Call User Exit Function
    select  v_message||c_bankstatement_post_userexit(v_Record_ID) into v_message;
    -- Finish Process
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, v_User, 'N', 1, v_Message) ;
    RETURN;
EXCEPTION
WHEN OTHERS THEN
  -- ROLLBACK;
  v_ResultStr:= '@ERROR=' || SQLERRM;
  RAISE NOTICE '%',v_ResultStr ;
  if v_nopinstance='Y' then
    raise exception '%',v_ResultStr;
  end if;
  PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', 0, v_ResultStr) ;
  RETURN;
END; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

-- User Exit to c_bankstatement_post
CREATE or replace FUNCTION c_bankstatement_post_userexit(p_bankstatement_id varchar) RETURNS varchar
AS $_$
DECLARE
  BEGIN
  RETURN '';
END;
$_$  LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('c_bankstatementline_trg', 'c_bankstatementline');

CREATE OR REPLACE FUNCTION c_bankstatementline_trg() RETURNS trigger
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
  *************************************************************************
   Issue 448: Delete Created Payments/Settlements when a line is deleted
              This is, when BsT is not Processed
              Create a correct difference with chargeamt*/
  v_Difference NUMERIC:=0;
  v_ID VARCHAR(32); --OBTG:VARCHAR2--
  v_RO NUMERIC;
  v_cur RECORD;
  
 -- sepa 
  v_isreceipt character(1);
  v_paymentrule character(1);
  v_count integer;
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  -- Difference, ID
  IF(TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    v_Difference:=new.trxAmt+ coalesce(new.chargeamt,0);
    v_ID:=new.C_BankStatement_ID;
  END IF;
  IF(TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
    v_Difference:=v_Difference - old.trxAmt - coalesce(old.chargeamt,0) ;
    v_ID:=old.C_BankStatement_ID;
  END IF;
  -- Delete Generated Settlements
  IF(TG_OP = 'DELETE') THEN
     for v_cur in (select * from c_settlement where bankstatementline=old.c_bankstatementline_id)
     LOOP
        -- Delete
        delete from c_debt_payment where c_settlement_generate_id=v_cur.c_settlement_id;
        update c_debt_payment set c_settlement_cancel_id=null where c_settlement_cancel_id=v_cur.c_settlement_id;
        delete from c_settlement where c_settlement_id=v_cur.c_settlement_id;
     END LOOP;
  END IF;


  
  -- Update header
  UPDATE C_BankStatement
    SET StatementDifference=StatementDifference + v_Difference,
    EndingBalance=EndingBalance + v_Difference
  WHERE C_BankStatement_ID=v_ID;
  
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;
  
ALTER FUNCTION c_bankstatementline_trg() OWNER TO tad;

CREATE TRIGGER c_bankstatementline_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON c_bankstatementline
  FOR EACH ROW
  EXECUTE PROCEDURE c_bankstatementline_trg();


SELECT zsse_droptrigger('c_bankstatementline_bef_trg', 'c_bankstatementline');

CREATE OR REPLACE FUNCTION c_bankstatementline_bef_trg() RETURNS trigger
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
***************************************************************************************************************************************************/
 v_isreceipt varchar;
 v_bankcurrency varchar;
 v_glcurrency varchar;
 v_temp numeric;

 v_paymentrule varchar;
 v_count integer;
 v_sepapaintype character(20);
 v1_debt_payment_id CHARACTER VARYING;
 
 v_amount numeric;
 v_paintype varchar;
 v_doctype varchar;
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;

  --SEPA-Export is only Possible on outgoing Payments (remittance) or incomming direct debits
  IF(TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
    select coalesce(sepapaintype,'NON') into v_paintype  from c_bankstatement WHERE c_bankstatement_id = NEW.c_bankstatement_id;
    SELECT dp.isreceipt, dp.paymentrule,dp.amount,i.c_doctype_id INTO v_isreceipt, v_paymentrule,v_amount, v_doctype FROM c_debt_payment dp left join c_invoice i
        on dp.c_invoice_id=i.c_invoice_id where dp.c_debt_payment_id = new.c_debt_payment_id;
    if v_paintype='NON' then
        new.sepaexportenabled:='N';
    end if;
    -- SEPA Lastschrift
    -- v_paymentrule = 'P' -> Bankeinzug (Oder Gutschrift zur Verrechnung)
    if v_paintype='pain.008' then
        IF v_paymentrule = 'P' and v_isreceipt='Y' and v_amount>0 
           OR (v_paymentrule = 'CNA' and v_amount<0 and coalesce(v_doctype,'')='A4277AD679DF4DD8A9C2BB9F3C2F2C92') THEN
           new.sepaexportenabled:='Y';
        else
         -- 'Ueberweisung kann dem Stapel fuer Lastschriften nicht hinzugefuegt werden'
           raise exception '%', '@sepaexportonlywithdirectdebits@';
        end if;
    end if;
    -- SEPA Überweisung (Oder Gutschrift zur Verrechnung)
    if v_paintype='pain.001'  then
        IF (v_paymentrule = 'R' and v_isreceipt='N' and v_amount>0) OR (v_paymentrule = 'R' and v_isreceipt='Y' and v_amount<0) 
           OR (v_paymentrule = 'CNA' and v_amount<0 and coalesce(v_doctype,'')='3CD24CAE0D074B8FA9918178780D50FB') THEN
           new.sepaexportenabled:='Y';
        else
           -- 'Lastschrift kann dem Stapel fuer Ueberweisungen nicht hinzugefuegt werden '
           raise exception '%', '@sepaexportonlywithpayments@';
        end if;
    end if;
    
    -- On Foreign currency Bank accounts only the specified foreign currency can be used
    select dp.c_currency_id into v_bankcurrency from ad_org_acctschema ac,c_acctschema s,c_bankaccount ba,c_bankstatement bs,c_debt_payment dp
            where bs.c_bankstatement_id=new.c_bankstatement_id 
            and   bs.c_bankaccount_id=ba.c_bankaccount_id
            and   s.c_acctschema_id=ac.c_acctschema_id 
            and   dp.c_debt_payment_id=new.c_debt_payment_id
            and   ac.ad_org_id=new.ad_org_id
            and   s.c_currency_id!=ba.c_currency_id;
    if coalesce(v_bankcurrency,new.c_currency_id)!=new.c_currency_id then
        raise exception '%','@WrongCurrencyOnForeignBank@';
    end if;
    select c_currency_id into v_bankcurrency from c_debt_payment  where c_debt_payment_id=new.c_debt_payment_id;
    select s.c_currency_id into v_glcurrency  from ad_org_acctschema o,c_acctschema s where o.ad_org_id=new.ad_org_id and o.c_acctschema_id=s.c_acctschema_id;
    -- Discount on Foreign Currency is not supported yet.
    -- if coalesce(new.discountamt,0)!=0 and (v_glcurrency!=new.c_currency_id or new.c_currency_id!=v_bankcurrency) then
        --   raise exception '%','@DiscountonForeignCurrencyNotSupported@'; 
    -- end if;
    -- Foreign Currency Convert
    -- Due to exiting structure we change the position here: Foreign Currency is in an extra field, Account Currency is the tranaction amt.
    -- in the field foreigncurrencyamt is the Account Currency filled in by the GUI, so the change is nbesessary here.
    --raise exception '%',new.c_currency_id||'-'||coalesce(v_bankcurrency,new.c_currency_id)||'-'||coalesce(new.foreigncurrencyamt,99999999)||coalesce(new.trxamt,1111111111);
    if new.c_currency_id!=v_bankcurrency then
        new.foreigncurrency:=v_bankcurrency;
        v_temp:=new.trxamt;
        new.trxamt:=new.foreigncurrencyamt ;
        new.foreigncurrencyamt:=v_temp;
        new.foreigncurrencyrate:=abs(round(new.foreigncurrencyamt/new.trxamt,4));
    end if;
  END IF;

  -- Im Zustand T1 (Sepa erzeugt) darf nicht gelöscht werden
  IF TG_OP = 'DELETE' THEN 
     if (select sepacollectioniscreated from c_bankstatement where c_bankstatement_id=old.c_bankstatement_id)='Y' then
            raise exception '%', 'Die Sepa Datei ist bereits erzeugt. Diese Zeile kann nicht gelöscht werden.';
     end if;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;

CREATE TRIGGER c_bankstatementline_bef_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON c_bankstatementline FOR EACH ROW
  EXECUTE PROCEDURE c_bankstatementline_bef_trg();

  
CREATE OR REPLACE FUNCTION c_bstmt_chk_restrictions_trg() RETURNS trigger LANGUAGE plpgsql  AS $_$ 
DECLARE 
v_Count NUMERIC;
v_DateNull TIMESTAMP := TO_DATE('01-01-1900', 'DD-MM-YYYY');
        
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


    IF TG_OP = 'UPDATE' THEN
     IF (old.Processed='Y'
        AND ((COALESCE(old.STATEMENTDATE, v_DateNull) <> COALESCE(new.STATEMENTDATE, v_DateNull))
        OR(COALESCE(old.C_BANKACCOUNT_ID, '0') <> COALESCE(new.C_BANKACCOUNT_ID, '0'))
        OR(COALESCE(old.AD_ORG_ID, '0') <> COALESCE(new.AD_ORG_ID, '0'))
        OR(COALESCE(old.AD_CLIENT_ID, '0') <> COALESCE(new.AD_CLIENT_ID, '0'))))
      THEN
      RAISE EXCEPTION '%', 'Document processed/posted'; --OBTG: -20501--
     END IF;
     begin
      SELECT COUNT(*)  INTO v_Count  FROM C_BankAccount b1, C_BankAccount b2  
             WHERE b1.C_BankAccount_ID = old.C_BankAccount_ID   AND b2.C_BankAccount_ID = new.C_BankAccount_ID  AND b2.C_Currency_ID != b1.C_Currency_ID
             AND EXISTS (SELECT 1  FROM C_BankStatementLine  WHERE C_BankStatement_ID = new.C_BankStatement_ID);
      exception when others then
       v_Count:=0;
      end;
       IF v_Count > 0 THEN
         RAISE EXCEPTION '%', 'Cannot change between bank account with different currency'; --OBTG:-20503--
       END IF;
       if coalesce(new.sepapaintype,'')!=coalesce(old.sepapaintype,'') and (select  COUNT(*) from c_bankstatementline where c_bankstatement_id=new.c_bankstatement_id)>0 then
             RAISE EXCEPTION '%', 'Cannot change the Type of SEPA statement if there are lines';
       end if;
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

  
  
SELECT zsse_droptrigger('c_bankstatement_aft_trg', 'c_bankstatement');

CREATE OR REPLACE FUNCTION c_bankstatement_aft_trg() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2014 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************/
v_count numeric;
v_line numeric;
BEGIN
    
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
  END IF;

  --SPropagate SEPA-Bankdate to lines
  IF(TG_OP = 'UPDATE') THEN
    if coalesce(new.sepapaintype,'NON')!='NON' and coalesce(new.sepabankdate,trunc(now()))!=coalesce(old.sepabankdate,trunc(now())) then
        update c_bankstatementline set valutadate=new.sepabankdate,dateacct=new.sepabankdate where c_bankstatement_id=new.c_bankstatement_id;
    end if;
    if new.ad_org_id!=old.ad_org_id then
         update c_bankstatementline set ad_org_id=new.ad_org_id where c_bankstatement_id=new.c_bankstatement_id;
    end if;
     SELECT COUNT(*),
        MAX(cl.Line)
      INTO v_count, v_line
      FROM C_BANKSTATEMENT c,        C_BANKSTATEMENTLINE cl,        C_DEBT_PAYMENT l,        C_BPARTNER bp
      WHERE c.C_BANKSTATEMENT_ID=cl.C_BANKSTATEMENT_ID
        AND c.C_BANKSTATEMENT_ID=new.c_bankstatement_id
        AND cl.C_DEBT_PAYMENT_ID=l.C_DEBT_PAYMENT_ID
        AND l.C_BPARTNER_ID=bp.C_BPARTNER_ID
        AND(Ad_Isorgincluded(l.AD_ORG_ID, bp.AD_ORG_ID, bp.AD_CLIENT_ID)=-1
        OR Ad_Isorgincluded(l.AD_ORG_ID, c.AD_ORG_ID, c.AD_CLIENT_ID)=-1) ;
      IF v_count>0 THEN
        RAISE EXCEPTION '%', '@Inline@'||v_line||' '||'@NotCorrectOrgDebtpaymentBankstatement@' ; 
      END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
END; $_$;

CREATE TRIGGER c_bankstatement_aft_trg
  after UPDATE
  ON c_bankstatement FOR EACH ROW
  EXECUTE PROCEDURE c_bankstatement_aft_trg();

select zsse_dropfunction ('zssi_getPartnerLineTrxAmt');
  
CREATE or replace FUNCTION zssi_getPartnerLineTrxAmt( p_bankstatementline_id character varying) RETURNS numeric
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s): Nur bei SEPA-Überweisungen Gutschriften gegenrechnen
***************************************************************************************************************************************************/
DECLARE
v_cur record;
v_trxamt numeric;
v_gutsch numeric;
v_trxamtges numeric:=0;
v_acct varchar;
v_bsid  varchar;
BEGIN
      select i.c_bpartner_id,abs(b.trxamt),b.c_bankstatement_id  into v_acct,v_trxamt,v_bsid 
      from c_debt_payment d ,c_bankstatementline b,c_invoice i where b.c_debt_payment_id=d.c_debt_payment_id
            and b.c_bankstatementline_id=p_bankstatementline_id and i.c_invoice_id=d.c_invoice_id; -- Aktuelle Zeile -> Überweisung
      if v_acct is null then
        RAISE EXCEPTION '%', 'No Business Partner? No Invoice?';
      end if;
      select sum(abs(b.trxamt)) into v_gutsch from c_bankstatementline b,c_debt_payment d,c_invoice i  where b.c_debt_payment_id=d.c_debt_payment_id and i.c_invoice_id=d.c_invoice_id
            and b.c_bankstatement_id=v_bsid and i.c_bpartner_id=v_acct and i.c_doctype_id in ( 'A4277AD679DF4DD8A9C2BB9F3C2F2C92','3CD24CAE0D074B8FA9918178780D50FB'); -- Summe Gutscrift
      if coalesce(v_gutsch,0)=0 then
        return v_trxamt;
      end if;
      -- Prüfen, ob Verrechnung möglich
      select sum(abs(b.trxamt)) into v_trxamtges from c_bankstatementline b,c_debt_payment d,c_invoice i  where b.c_debt_payment_id=d.c_debt_payment_id and i.c_invoice_id=d.c_invoice_id
            and b.c_bankstatement_id=v_bsid and i.c_bpartner_id=v_acct and i.c_doctype_id not in ( 'A4277AD679DF4DD8A9C2BB9F3C2F2C92','3CD24CAE0D074B8FA9918178780D50FB'); -- Summe Überweisungen
      if v_trxamtges < v_gutsch then
        RAISE EXCEPTION '%', 'Verrechnung der Gutschriften nicht Möglich. Transaktionsbetrag kleiner Gutschriftbetrag';
      end if;
      -- Verrechnungs-Algorithmus.
      for v_cur in (select abs(b.trxamt) as amt,b.c_bankstatementline_id   from c_bankstatementline b,c_debt_payment d,c_invoice i where b.c_debt_payment_id=d.c_debt_payment_id and i.c_invoice_id=d.c_invoice_id
            and b.c_bankstatement_id=v_bsid and i.c_bpartner_id=v_acct and i.c_doctype_id not in ( 'A4277AD679DF4DD8A9C2BB9F3C2F2C92','3CD24CAE0D074B8FA9918178780D50FB')  -- Summe Überweisungen
            order by b.c_bankstatementline_id) 
      LOOP
        if v_cur.c_bankstatementline_id!=p_bankstatementline_id then -- Andere Überweisung
            if v_cur.amt - v_gutsch > 0 then
                v_gutsch:=0;
                return v_trxamt;
            else
                v_gutsch:=v_gutsch-v_cur.amt+0.01;
            end if;
        else -- Aktuelle Zeile
            if v_cur.amt - v_gutsch > 0 then
                return v_cur.amt - v_gutsch; -- Betrag kann verrechnet werden
            else
                return 0.01;
            end if;
        end if;
      END LOOP;
RAISE EXCEPTION '%', 'Not Expected - End of Control Block --zssi_getPartnerLineTrxAmt';
RETURN 0;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

select zsse_dropfunction ('zssi_getPartnerLineMemo');
  
CREATE or replace FUNCTION zssi_getPartnerLineMemo( p_bankstatementline_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2017 Stefan Zimmermann All Rights Reserved.
Contributor(s):
***************************************************************************************************************************************************/
DECLARE
v_cur record;
v_memo varchar;
v_gutsch varchar;
v_trxamtges numeric:=0;
v_acct varchar;
v_bsid  varchar;
BEGIN
     select i.c_bpartner_id,substr(coalesce(memo,'-'),1,140),c_bankstatement_id  into v_acct,v_memo,v_bsid 
     from c_debt_payment d ,c_bankstatementline b,c_invoice i where b.c_debt_payment_id=d.c_debt_payment_id
            and b.c_bankstatementline_id=p_bankstatementline_id and i.c_invoice_id=d.c_invoice_id; -- Aktuelle Zeile -> Überweisung
     select ',-'||string_agg(i.documentno||':'||coalesce(i.poreference,''),',') into  v_gutsch from c_bankstatementline b,c_debt_payment d,c_invoice i  where b.c_debt_payment_id=d.c_debt_payment_id and i.c_invoice_id=d.c_invoice_id
            and b.c_bankstatement_id=v_bsid and i.c_bpartner_id=v_acct and i.c_doctype_id in ( 'A4277AD679DF4DD8A9C2BB9F3C2F2C92','3CD24CAE0D074B8FA9918178780D50FB'); -- Summe Gutscrift
     if v_gutsch is not null then
        RETURN substr(replace(v_memo,' ','')||replace(v_gutsch,' ',''),1,140);
     else
        return v_memo;
     end if;
END; 
$_$  LANGUAGE 'plpgsql' VOLATILE COST 100;  
  
select zsse_dropfunction ('zssi_getOwnBankaccountFromBankstatement');

CREATE or replace FUNCTION zssi_getOwnBankaccountFromBankstatement(p_bankstatement_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************/
DECLARE
v_acct character varying;
v_org  character varying;
BEGIN
      select c_bankaccount_id,ad_org_id into v_acct,v_org from c_bankstatement where c_bankstatement_id=p_bankstatement_id;
RETURN v_acct;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;

/* overload function: bankaccount for sepa remittance */
select zsse_dropfunction ('zssi_getpartnerbankaccountfromdebtpayment');
  
CREATE or replace FUNCTION zssi_getPartnerBankaccountFromDebtPayment( p_debt_payment_id character varying) RETURNS character varying
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************/
DECLARE
v_partner character varying;
v_acct character varying;
v_org  character varying;
v_partnername varchar;
BEGIN
      select c_bp_bankaccount_id  into v_acct from c_debt_payment where c_debt_payment_id=p_debt_payment_id;
      select c_bp_bankaccount_id  into v_acct from c_bp_bankaccount where c_bp_bankaccount_id=v_acct and isactive='Y';
       if v_acct is null then
              select p.c_bpartner_id,b.name,p.ad_org_id into v_partner,v_partnername,v_org from c_debt_payment p, c_bpartner b where b.c_bpartner_id=p.c_bpartner_id and p.c_debt_payment_id=p_debt_payment_id;
              select c_bp_bankaccount_id into v_acct from c_bp_bankaccount where ad_org_id in ('0',v_org) and c_bpartner_id=v_partner and isactive='Y';
      end if;
      if v_acct is null then
         RAISE EXCEPTION '%', 'Keine Bankverbindung fuer Ueberweisungs-Empfaenger '||v_partnername||' vorhanden.';
      end if;
RETURN v_acct;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


/* overload function: bankaccount for collection / sepa direct debit */  
CREATE OR REPLACE FUNCTION zssi_getpartnerbankaccountfromdebtpayment(p_debt_payment_id character varying, p_isDirectDebit boolean)
  RETURNS character varying AS
$_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Martin Hinrichs
***************************************************************************************************************************************************/
DECLARE
 v_partner_id character varying;
 v_acct character varying;
 v_org  character varying;
 v_partnername varchar;
-- sepa
 v_mndtident character varying;
 v_dtofsgntr date; 
 v_bic character varying; 
 v_iban character varying;
-- 
 v_mess CHARACTER VARYING := ''; 
BEGIN
  select p.c_bpartner_id, b.name, p.ad_org_id ,p.c_bp_bankaccount_id
  into v_partner_id, v_partnername, v_org ,v_acct
  from c_debt_payment p, c_bpartner b 
  where b.c_bpartner_id = p.c_bpartner_id 
  and p.c_debt_payment_id = p_debt_payment_id; -- 'BAFF7536EB7246369660D9399D634479';
  select c_bp_bankaccount_id  into v_acct from c_bp_bankaccount where c_bp_bankaccount_id=v_acct and isactive='Y';

  IF (p_isDirectDebit) THEN
    if  v_acct is null then
            select c_bp_bankaccount_id, mndtident, dtofsgntr, swiftcode, iban
            into v_acct, v_mndtident, v_dtofsgntr, v_bic, v_iban
            from c_bp_bankaccount  
            where 1=1
            and c_bpartner_id = v_partner_id -- 0A782B07D1874371A1B58F8F06E5F3D9'
            and isactive = 'Y'
            AND mndtident IS NOT NULL AND dtofsgntr IS NOT NULL -- SEPA direct debit
            LIMIT 1; -- get only first record
    else
            select  mndtident, dtofsgntr, swiftcode, iban
            into v_mndtident, v_dtofsgntr, v_bic, v_iban
            from c_bp_bankaccount  
            where c_bp_bankaccount_id=v_acct;
    end if;
  
  -- if not found partner or bankaccout, return input-param for information
    if (v_acct is null) then
      v_mess := '@sepa_missing_partner_account_direct_debit@' || ' (' || COALESCE(v_partnername, 'p_debt_payment_id='''||p_debt_payment_id) || ''')';  -- 'Keine Bankverbindung fuer SEPA-Lastschrift '' vorhanden.'
   -- raise notice '%', v_mess;
      RAISE EXCEPTION '%', v_mess;
      RETURN NULL;
    end if;

    IF (v_bic IS NULL) OR (LENGTH(v_bic) = 0) THEN
      v_mess := '@sepa_missing_mandate_BIC@' ||  ' (' || COALESCE(v_partnername, 'p_debt_payment_id='''||p_debt_payment_id) || ''')';
      RAISE EXCEPTION '%', v_mess;
    END IF;
    IF (v_iban IS NULL) OR (LENGTH(v_iban) = 0) THEN
      v_mess := '@sepa_missing_mandate_IBAN@'||  ' (' || COALESCE(v_partnername, 'p_debt_payment_id='''||p_debt_payment_id) || ''')';
      RAISE EXCEPTION '%', v_mess;
    END IF;
  END IF; 
       
  RETURN v_acct; -- c_bp_bankaccount_id
EXCEPTION 
  WHEN OTHERS THEN 
  v_mess := COALESCE(v_mess, 'error in function ' || 'zssi_getpartnerbankaccountfromdebtpayment(character, boolean)');
  RAISE EXCEPTION '%', v_mess;
  RETURN NULL;
END;
$_$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE or replace FUNCTION c_ApproveDebtPayments(p_user_id varchar,p_debt_payment_id_list varchar,approve varchar) RETURNS varchar
AS $_$
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): Frank Wohlers
***************************************************************************************************************************************************/
DECLARE
   v_approved varchar;
   v_rowcount numeric;
BEGIN
    if approve='APPROVE' then
      v_approved='Y';
    else
      v_approved='N';
    end if;
    UPDATE C_DEBT_PAYMENT
        SET ISAPPROVED = v_approved,
            UPDATEDBY = p_user_id,
            APPROVEDBY = p_user_id,
            APPROVALDATE =  now(),
            UPDATED = now()
        WHERE C_DEBT_PAYMENT_ID  IN (p_debt_payment_id_list) and ISAPPROVED= case v_approved when 'Y' then 'N' else 'Y' end;     
    GET DIAGNOSTICS v_rowcount = ROW_COUNT;
    RETURN to_char(coalesce(v_rowcount,0));
END;
$_$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION c_debt_payment_create(p_pinstance_id character varying) RETURNS void
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
  --  Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  v_AD_User_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    --Parameter variables
    v_C_BPartner_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_Amount NUMERIC;
    v_C_Currency_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_PaymentRule VARCHAR(60) ; --OBTG:VARCHAR2--
    v_DatePlanned TIMESTAMP;
    v_IsReceipt VARCHAR(1) ; --OBTG:VARCHAR2--
    v_Description VARCHAR ; --OBTG:VARCHAR2--
    v_Status VARCHAR(60); --OBTG:VARCHAR2--
    --Local variables
    v_Client_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_AD_Org_ID VARCHAR(32); --OBTG:VARCHAR2--
    v_settlementID VARCHAR(32):=NULL; --OBTG:varchar2--
    v_SettlementDocType_ID VARCHAR(32) ; --OBTG:VARCHAR2--
    v_SDocumentNo C_SETTLEMENT.DocumentNo%TYPE;
    v_debtPaymentID VARCHAR(32) ; --OBTG:varchar2--
    v_CBankAccount_ID C_BankStatement.C_BankAccount_ID%TYPE;
  v_C_BankCurrency VARCHAR(32); --OBTG:VARCHAR2--
  v_BS_Date TIMESTAMP;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    --  Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID,
        p.ParameterName,
        p.P_String,
        p.P_Number,
        p.P_Date,
        i.AD_USER_ID
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      )
    LOOP
      v_Record_ID:=Cur_Parameter.Record_ID;
      v_AD_User_ID:=Cur_Parameter.AD_User_ID;
      IF(Cur_Parameter.ParameterName='C_BPartner_ID') THEN
        v_C_BPartner_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  C_BPartner_ID=' || v_C_BPartner_ID ;
      ELSIF(Cur_Parameter.ParameterName='Amount') THEN
        v_Amount:=Cur_Parameter.P_Number;
        RAISE NOTICE '%','  Amount=' || v_Amount ;
      ELSIF(Cur_Parameter.ParameterName='C_Currency_ID') THEN
        v_C_Currency_ID:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  C_Currency_ID=' || v_C_Currency_ID ;
      ELSIF(Cur_Parameter.ParameterName='PaymentRule') THEN
        v_PaymentRule:=Cur_Parameter.P_String;
        RAISE NOTICE '%','  v_PaymentRule=' || v_PaymentRule ;
      ELSIF(Cur_Parameter.ParameterName='Dateplanned') THEN
        v_DatePlanned:=Cur_Parameter.P_Date;
        RAISE NOTICE '%','  DatePlanned=' || v_DatePlanned ;
      ELSIF(Cur_Parameter.ParameterName='IsReceipt') THEN
        v_IsReceipt:=Cur_Parameter.p_String;
        RAISE NOTICE '%','  IsReceipt='||v_IsReceipt ;
      ELSIF(Cur_Parameter.ParameterName='Description') THEN
        v_Description:=Cur_Parameter.p_String;
        RAISE NOTICE '%','  Description='||v_Description ;
      ELSIF(Cur_Parameter.ParameterName='Status') THEN
        v_Status:=Cur_Parameter.p_String;
        RAISE NOTICE '%','  Status='||v_Status ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; --  Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    --Read bank statement
    v_ResultStr:='ReadingBankStatementLine '||v_record_Id;
    SELECT L.AD_Client_ID,
      L.AD_Org_ID,
      B.C_BankAccount_ID
    INTO v_Client_ID,
      v_AD_Org_ID,
      v_CBankAccount_ID
    FROM C_BankStatementLine L,
      C_BankStatement B
    WHERE L.C_BankStatementLine_ID=v_Record_ID
      AND L.C_BankStatement_ID=B.C_BankStatement_ID;
    --Insert Settlement
    v_ResultStr:='InsertingSettlement';
    v_SettlementDocType_ID:=Ad_Get_DocType(v_Client_ID, v_AD_Org_ID, TO_CHAR('STT')) ;
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
        C_CURRENCY_ID, Description, ISGENERATED
      )
      /*, C_PROJECT_ID, C_CAMPAIGN_ID,
      C_ACTIVITY_ID, USER1_ID, USER2_ID, CREATEFROM)*/
      VALUES
      (
        v_SettlementID, v_Client_ID, v_AD_Org_ID, 'Y',
        TO_DATE(NOW()), v_AD_User_ID, TO_DATE(NOW()), v_AD_User_ID,
        '*DPC*'||v_SDocumentNo, trunc(TO_DATE(NOW())), trunc(TO_DATE(NOW())), 'C',
        v_SettlementDocType_ID, 'N', 'N', 'N',
        v_C_Currency_ID, v_Description, 'Y'
      )
      ;
    --Insert generated debt payment
    v_ResultStr:='InsertingGeneratedDebtPayement';
    SELECT * INTO  v_debtPaymentID FROM Ad_Sequence_Next('C_Debt_Payment', v_Record_ID) ;
    INSERT
    INTO C_DEBT_PAYMENT
      (
        C_DEBT_PAYMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
        CREATED, CREATEDBY, UPDATED, UPDATEDBY,
        ISRECEIPT, C_SETTLEMENT_GENERATE_ID, DESCRIPTION, C_INVOICE_ID,
        C_BPARTNER_ID, C_CURRENCY_ID,
        /* C_CASHLINE_ID, C_BANKACCOUNT_ID, C_CASHBOOK_ID,*/
        PAYMENTRULE, ISPAID, AMOUNT, WRITEOFFAMT, DATEPLANNED,
        ISMANUAL, ISVALID,
        /*C_BANKSTATEMENTLINE_ID,*/
        CHANGESETTLEMENTCANCEL, CANCEL_PROCESSED, GENERATE_PROCESSED, STATUS_INITIAL
      )
      VALUES
      (
        v_debtPaymentID, v_Client_ID, v_AD_Org_ID, 'Y',
        TO_DATE(NOW()), v_AD_User_ID, TO_DATE(NOW()), v_AD_User_ID,
        v_IsReceipt, v_settlementID, v_Description, null,
        v_C_BPartner_ID, v_C_Currency_ID,
        v_PaymentRule, 'N', v_Amount*(-1), 0, v_DatePlanned,
        'N', 'Y',
        'N', 'N', 'Y', v_Status
      )
      ;
    SELECT * INTO  v_debtPaymentID FROM Ad_Sequence_Next('C_Debt_Payment', v_Record_ID) ;
    --We insert it in the positive side of the bank account
    INSERT
    INTO C_DEBT_PAYMENT
      (
        C_DEBT_PAYMENT_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE,
        CREATED, CREATEDBY, UPDATED, UPDATEDBY,
        ISRECEIPT, C_SETTLEMENT_GENERATE_ID, DESCRIPTION, C_INVOICE_ID,
        C_BPARTNER_ID, C_CURRENCY_ID,
        /* C_CASHLINE_ID,*/
        C_BANKACCOUNT_ID,
        /*C_CASHBOOK_ID,*/
        PAYMENTRULE, ISPAID, AMOUNT, WRITEOFFAMT,
        DATEPLANNED, ISMANUAL, ISVALID,
        /*C_BANKSTATEMENTLINE_ID,*/
        CHANGESETTLEMENTCANCEL, CANCEL_PROCESSED, GENERATE_PROCESSED, STATUS_INITIAL
      )
      VALUES
      (
        v_debtPaymentID, v_Client_ID, v_AD_Org_ID, 'Y',
        TO_DATE(NOW()), v_AD_User_ID, TO_DATE(NOW()), v_AD_User_ID,
        v_IsReceipt, v_settlementID, v_Description, null,
        v_C_BPartner_ID, v_C_Currency_ID,
        v_CBankAccount_ID,
        v_PaymentRule, 'N', v_Amount, 0,
        v_DatePlanned, 'N', 'Y',
        'N', 'N', 'Y', v_Status
      )
      ;
    PERFORM C_SETTLEMENT_POST(null, v_settlementID);

  SELECT ba.C_Currency_ID, bs.STATEMENTDATE
    INTO v_C_BankCurrency, v_BS_Date
    FROM C_BankStatementLine bsl,
        C_BankStatement     bs,
      C_BankAccount    ba
   WHERE bsl.C_BankStatement_ID = bs.C_BankStatement_ID
     AND ba.C_BankAccount_ID = bs.C_BankAccount_ID
    AND bsl.C_BankStatementLine_ID = v_Record_ID;

  v_Amount := C_Currency_Convert(v_Amount, v_C_Currency_ID, v_C_BankCurrency, v_BS_Date, NULL, v_Client_ID, v_AD_Org_ID);

    UPDATE C_BankStatementLine
      SET C_Debt_Payment_ID=v_debtPaymentID,
      TrxAmt=((CASE v_IsReceipt WHEN 'Y' THEN 1 ELSE -1 END )) *v_Amount,
      StmtAmt=((CASE v_IsReceipt WHEN 'Y' THEN 1 ELSE -1 END)) *v_Amount,
      C_Currency_ID=v_C_BankCurrency,
      Description=v_Description,
      Updated=TO_DATE(NOW()),
      UpdatedBy=v_AD_User_ID,
      C_Debt_Payment_Create='Y'
    WHERE C_BankStatementLine_ID=v_Record_ID;
    --  v_Message := 'Sett: '||v_SettlementID||' debt: '||v_debtPaymentID;
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
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


CREATE OR REPLACE FUNCTION c_bankaccountiban_trg() RETURNS trigger
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
  * All portions are Copyright (C) 2001-2009 Openbravo SL
  * All Rights Reserved.
  * Contributor(s):  ______________________________________.
  ************************************************************************/

  v_IBAN_check NUMERIC;
  v_Bank VARCHAR(4); --OBTG:NVARCHAR2--
  v_Branch VARCHAR(4); --OBTG:NVARCHAR2--
  v_DigitBank VARCHAR(1); --OBTG:NVARCHAR2--
  v_Location VARCHAR(32); --OBTG:NVARCHAR2--
  v_CountryId VARCHAR(2); --OBTG:NVARCHAR2--
  v_BankName VARCHAR(60); --OBTG:NVARCHAR2--
  v_Length NUMERIC;
  v_ShortLength NUMERIC;
  v_BankNameLength NUMERIC;
  v_CodeAccountLength NUMERIC;
  v_ProposedDisplayedAccount VARCHAR(512); --OBTG:NVARCHAR2--
  v_LimitLength NUMERIC:=50;
  v_LastNumAccount NUMERIC:=4;
  v_AccountSeparator VARCHAR(5):='(...)'; --OBTG:NVARCHAR2--
  v_BankSeparator VARCHAR(3):='...'; --OBTG:NVARCHAR2--
  v_I_AccountNumberOrig VARCHAR(60); --OBTG:NVARCHAR2--
  v_I_AccountNumberFinal VARCHAR(600):=''; --OBTG:NVARCHAR2--
  v_i_char VARCHAR(2); --OBTG:NVARCHAR2--
  v_i_char_ascii NUMERIC;
  v_i NUMERIC:=1;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;

   if not ((new.showiban = 'Y' AND new.showgeneric = 'N' AND new.iban IS NOT NULL and (select swiftcode from c_bank where c_bank_id=new.c_bank_id) is not null) 
         OR (new.showiban = 'N' AND new.showgeneric = 'Y' AND new.genericaccount IS NOT NULL)) then
        raise exception '%','@ifIbanNoacctIbanNotNullIfAcctNoIbanAcctNotNull@';
    end if;
  --  Default Accounts for all AcctSchema
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    SELECT NAME
    INTO v_BankName
    FROM C_BANK
    WHERE C_BANK_ID=NEW.C_BANK_ID;
    IF (NEW.CODEACCOUNT IS NOT NULL OR NEW.DIGITCONTROL IS NOT NULL) THEN
      SELECT CODEBANK, CODEBRANCH, DIGITCONTROL
      INTO v_Bank, v_Branch, v_DigitBank
      FROM C_BANK
      WHERE C_BANK_ID=NEW.C_BANK_ID;
      IF (v_Bank IS NULL OR v_Branch IS NULL OR v_DigitBank IS NULL) THEN
        RAISE EXCEPTION '%', 'Bank information is missing.'; --OBTG:-20258--
      END IF;
    END IF;
    IF (NEW.IBAN IS NOT NULL) THEN
    
        v_I_AccountNumberOrig:=SUBSTR(NEW.IBAN, 5, LENGTH(NEW.IBAN)-4);
        v_CodeAccountLength:=LENGTH(v_I_AccountNumberOrig);
        WHILE (v_i<=v_CodeAccountLength) LOOP 
          v_i_char:=SUBSTR(v_I_AccountNumberOrig, v_i, 1);
          v_i_char_ascii:=ASCII(v_i_char);
          --It is not a number, transforming to number
          IF ((v_i_char_ascii<48) OR (v_i_char_ascii>57)) THEN
            v_i_char:=TO_CHAR(v_i_char_ascii-55);
          END IF;
          v_I_AccountNumberFinal:=v_I_AccountNumberFinal||v_i_char;
          v_i:=v_i+1;
        END LOOP;
       
        SELECT MOD(TO_NUMBER(v_I_AccountNumberFinal||
                            TRIM(TO_CHAR(ASCII(SUBSTR(UPPER(NEW.IBAN),1,1))-55))
                            ||TRIM(TO_CHAR(ASCII(SUBSTR(UPPER(NEW.IBAN),2,1))-55))||
                            SUBSTR(NEW.IBAN,3,2)
                            , '999999999999999999999999999999999999999999999999999999999999'
		                     )
                   ,97) AS DC
           INTO v_IBAN_check
        FROM DUAL;        
        IF (v_IBAN_check <> 1) THEN
          RAISE EXCEPTION '%', 'Incorrect IBAN Code.'; --OBTG:-20257--
        END IF;
        SELECT C_LOCATION_ID
        INTO v_Location
        FROM C_BANK
        WHERE C_BANK_ID=NEW.C_BANK_ID;
        IF (v_Location IS NULL) THEN
          RAISE EXCEPTION '%', 'Bank does not have country defined.'; --OBTG:-20260--
        END IF;
        SELECT IBANCOUNTRY, IBANNODIGITS
        INTO v_CountryId, v_Length
        FROM C_COUNTRY
        WHERE C_COUNTRY_ID=(
          SELECT C_COUNTRY_ID
          FROM C_LOCATION
          WHERE C_LOCATION_ID=v_Location
          );
        IF ((v_CountryId IS NULL OR v_Length IS NULL) OR (v_CountryId <> SUBSTR(UPPER(NEW.IBAN),1,2) OR v_Length <> LENGTH(NEW.IBAN))) THEN
          RAISE EXCEPTION '%', 'The IBAN number defined in the bank account tab, must fit the IBAN data of the country defined in the bank tab.'; --OBTG:-20259--
        END IF;
      END IF;
    IF (NEW.SHOWSPANISH='Y') THEN
      SELECT CODEBANK, CODEBRANCH, DIGITCONTROL
      INTO v_Bank, v_Branch, v_DigitBank
      FROM C_BANK
      WHERE C_BANK_ID=NEW.C_BANK_ID;
      
      SELECT v_BankName || '. ' || v_Bank || '-' || v_Branch || '-' || v_DigitBank || NEW.DIGITCONTROL || '-' || NEW.CODEACCOUNT, 
             LENGTH(v_BankName || '. ' || v_Bank || '-' || v_Branch || '-' || v_DigitBank || NEW.DIGITCONTROL || '-' || NEW.CODEACCOUNT)
      INTO v_ProposedDisplayedAccount, v_Length
      FROM DUAL;

      IF (v_Length > v_LimitLength) THEN
       SELECT LENGTH(NEW.CODEACCOUNT), LENGTH(v_BankName)
       INTO v_CodeAccountLength, v_BankNameLength
       FROM DUAL;
       --Remove some letters of the bank name
       SELECT SUBSTR(v_ProposedDisplayedAccount, 1, v_BankNameLength-(v_Length-v_LimitLength+LENGTH(v_BankSeparator)-1)) || v_BankSeparator || SUBSTR(v_ProposedDisplayedAccount, v_BankNameLength+LENGTH(v_BankSeparator)-1, v_Length)
       INTO v_ProposedDisplayedAccount
       FROM DUAL;
      END IF;


    ELSIF (NEW.SHOWIBAN='Y') THEN
      SELECT v_BankName || '. ' || SUBSTR(UPPER(NEW.IBAN),1,4) || '-' || SUBSTR(NEW.IBAN, 5, LENGTH(NEW.IBAN)-4),
             LENGTH(v_BankName || '. ' || SUBSTR(UPPER(NEW.IBAN),1,4) || '-' || SUBSTR(NEW.IBAN, 5, LENGTH(NEW.IBAN)-4)), 
             LENGTH(v_BankName)
      INTO v_ProposedDisplayedAccount, v_Length, v_BankNameLength
      FROM DUAL;
      
      IF (v_Length > v_LimitLength) THEN
        SELECT v_Length + LENGTH(v_AccountSeparator) - v_LimitLength, LENGTH(SUBSTR(NEW.IBAN, 5, LENGTH(NEW.IBAN)-4))
        INTO v_ShortLength, v_CodeAccountLength
        FROM DUAL;
        IF (v_ShortLength < v_CodeAccountLength-v_LastNumAccount) THEN
          --Remove some account numbers
          SELECT SUBSTR(v_ProposedDisplayedAccount, 1, v_Length-v_CodeAccountLength+v_CodeAccountLength-v_LastNumAccount-v_ShortLength) || v_AccountSeparator || SUBSTR(v_ProposedDisplayedAccount, v_Length-v_LastNumAccount+1, v_Length)
          INTO v_ProposedDisplayedAccount
          FROM DUAL;     
        ELSE
          --Remove some letters of the bank name
          SELECT SUBSTR(v_ProposedDisplayedAccount, 1, v_BankNameLength-(v_Length-v_LimitLength+LENGTH(v_BankSeparator)-1)) || v_BankSeparator || SUBSTR(v_ProposedDisplayedAccount, v_BankNameLength+LENGTH(v_BankSeparator)-1, v_Length)
          INTO v_ProposedDisplayedAccount
          FROM DUAL;       
        END IF;     
      END IF;

    ELSE
      SELECT v_BankName || '. ' || NEW.GENERICACCOUNT, 
             LENGTH(v_BankName || '. ' || NEW.GENERICACCOUNT),
             LENGTH(v_BankName)
      INTO v_ProposedDisplayedAccount, v_Length, v_BankNameLength
      FROM DUAL;
      IF (v_Length > v_LimitLength) THEN
        SELECT v_Length + LENGTH(v_AccountSeparator) - v_LimitLength, LENGTH(NEW.GENERICACCOUNT)
        INTO v_ShortLength, v_CodeAccountLength
        FROM DUAL;
        IF (v_ShortLength < v_CodeAccountLength-v_LastNumAccount) THEN
          --Remove some account numbers
          SELECT SUBSTR(v_ProposedDisplayedAccount, 1, v_Length-v_CodeAccountLength+v_CodeAccountLength-v_LastNumAccount-v_ShortLength) || v_AccountSeparator || SUBSTR(v_ProposedDisplayedAccount, v_Length-v_LastNumAccount+1, v_Length)
          INTO v_ProposedDisplayedAccount
          FROM DUAL;     
        ELSE
          --Remove some letters of the bank name
          SELECT SUBSTR(v_ProposedDisplayedAccount, 1, v_BankNameLength-(v_Length-v_LimitLength+LENGTH(v_BankSeparator)-1)) || v_BankSeparator || SUBSTR(v_ProposedDisplayedAccount, v_BankNameLength+LENGTH(v_BankSeparator)-1, v_Length)
          INTO v_ProposedDisplayedAccount
          FROM DUAL;
        END IF;    
      END IF;     
    END IF;
    
    
    NEW.DISPLAYEDACCOUNT:=v_ProposedDisplayedAccount; 
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

EXCEPTION
 WHEN DATA_EXCEPTION THEN
  RAISE EXCEPTION '%', 'Incorrect IBAN Code.' ; --OBTG:-20257--
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END 

; $_$;


CREATE OR REPLACE FUNCTION c_bp_bankaccountiban_trg() RETURNS trigger
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
    * $Id: A_ASSET_Trg.sql,v 1.4 2002/10/23 03:16:57 jjanke Exp $
    ***
    * Title: Asset new necord
    * Description:
    *    - create default Account records
    ************************************************************************/

  v_IBAN_check NUMERIC;
  v_Bank VARCHAR(4); --OBTG:NVARCHAR2--
  v_Branch VARCHAR(4); --OBTG:NVARCHAR2--
  v_DigitBank VARCHAR(1); --OBTG:NVARCHAR2--
  v_CountryId VARCHAR(2); --OBTG:NVARCHAR2--
  v_Length NUMERIC;
  
  v_CodeAccountLength NUMERIC;
  v_I_AccountNumberOrig VARCHAR(60); --OBTG:NVARCHAR2--
  v_I_AccountNumberFinal VARCHAR(600):=''; --OBTG:NVARCHAR2--
  v_i_char VARCHAR(2); --OBTG:NVARCHAR2--
  v_i_char_ascii NUMERIC;
  v_i NUMERIC:=1;
    
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  --  Default Accounts for all AcctSchema
  IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    -- Check Contraints with app. error msg..
    if (new.showiban='Y' and new.showaccountno='Y') OR (new.showiban='N' and new.showaccountno='N') then
        raise exception '%','@ibanOrAcct@';
    end if;
    if new.iban IS not NULL and new.c_country_id IS  NULL then
        raise exception '%','@ibanneedscountry@';
    end if;
    if not ((new.showiban = 'Y' AND new.showaccountno = 'N' AND new.iban IS NOT NULL and new.swiftcode is not null) 
         OR (new.showiban = 'N' AND new.showaccountno = 'Y' AND new.accountno IS NOT NULL and new.a_zip is not null)) then
        raise exception '%','@ifIbanNoacctIbanNotNullIfAcctNoIbanAcctNotNull@';
    end if;
    IF (NEW.IBAN IS NOT NULL) THEN
        
        v_I_AccountNumberOrig:=SUBSTR(NEW.IBAN, 5, LENGTH(NEW.IBAN)-4);
        v_CodeAccountLength:=LENGTH(v_I_AccountNumberOrig);
        WHILE (v_i<=v_CodeAccountLength) LOOP 
         v_i_char:=SUBSTR(v_I_AccountNumberOrig, v_i, 1);
         v_i_char_ascii:=ASCII(v_i_char);
         --It is not a number, transforming to number
         IF ((v_i_char_ascii<48) OR (v_i_char_ascii>57)) THEN
           v_i_char:=TO_CHAR(v_i_char_ascii-55);
         END IF;
         v_I_AccountNumberFinal:=v_I_AccountNumberFinal||v_i_char;
         v_i:=v_i+1;
        END LOOP;
 
    
        SELECT MOD(TO_NUMBER(v_I_AccountNumberFinal||
                            TRIM(TO_CHAR(ASCII(SUBSTR(UPPER(NEW.IBAN),1,1))-55))
                            ||TRIM(TO_CHAR(ASCII(SUBSTR(UPPER(NEW.IBAN),2,1))-55))||
                            SUBSTR(NEW.IBAN,3,2)
                            , '999999999999999999999999999999999999999999999999999999999999'
                            )
                   ,97) AS DC
        INTO v_IBAN_check
        FROM DUAL;
        IF (v_IBAN_check <> 1) THEN
          RAISE EXCEPTION '%', 'Incorrect IBAN Code.'; --OBTG:-20257--
        END IF;
        SELECT IBANCOUNTRY, IBANNODIGITS
        INTO v_CountryId, v_Length
        FROM C_COUNTRY
        WHERE C_COUNTRY_ID=NEW.C_COUNTRY_ID;
        IF ((v_CountryId IS NULL OR v_Length IS NULL) OR (v_CountryId <> SUBSTR(UPPER(NEW.IBAN),1,2) OR v_Length <> LENGTH(NEW.IBAN))) THEN
          RAISE EXCEPTION '%', 'The IBAN number defined in the bank account tab, must fit the IBAN data of the country defined in the bank tab:'||coalesce(NEW.IBAN,'NULL'); --OBTG:-20259--
        END IF;
      END IF;
    IF (NEW.SHOWIBAN='Y') THEN
      NEW.DISPLAYEDACCOUNT:=SUBSTR(NEW.IBAN,1,4) || '-' || SUBSTR(NEW.IBAN, 5, LENGTH(NEW.IBAN)-4);
    ELSE
      NEW.DISPLAYEDACCOUNT:=NEW.ACCOUNTNO;
    END IF;
  END IF;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

EXCEPTION WHEN DATA_EXCEPTION THEN
  RAISE EXCEPTION '%', 'Incorrect IBAN Code.' ; --OBTG:-20257--
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END ; $_$;




CREATE OR REPLACE FUNCTION c_debt_payment_change(p_pinstance_id character varying) RETURNS void
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
  --  Logistice
  v_ResultStr VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Message VARCHAR(2000):=''; --OBTG:VARCHAR2--
  v_Result NUMERIC:=1; -- 0=failure
  v_Record_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  v_AD_User_ID VARCHAR(32) ; --OBTG:VARCHAR2--
  --  Parameter
  --TYPE RECORD IS REFCURSOR;
    Cur_Parameter RECORD;
    --  Parameter Variables
    v_Aux NUMERIC;
    v_IsPaid CHAR(1) ;
    FINISH_PROCESS BOOLEAN:=false;
  BEGIN
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Processing ' || p_PInstance_ID ;
    v_ResultStr:='PInstanceNotFound';
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
  BEGIN --BODY
    --  Get Parameters
    v_ResultStr:='ReadingParameters';
    FOR Cur_Parameter IN
      (SELECT i.Record_ID,
        p.ParameterName,
        p.P_String,
        p.P_Number,
        p.P_Date,
        i.AD_USER_ID
      FROM AD_PInstance i
      LEFT JOIN AD_PInstance_Para p
        ON i.AD_PInstance_ID=p.AD_PInstance_ID
      WHERE i.AD_PInstance_ID=p_PInstance_ID
      ORDER BY p.SeqNo
      )
    LOOP
      v_Record_ID:=Cur_Parameter.Record_ID;
      v_AD_User_ID:=Cur_Parameter.AD_User_ID;
      IF(Cur_Parameter.ParameterName='GetOutSettlement') THEN
        -- SZ Obsolete
        RAISE NOTICE '%','  GetOutSettlement=' || v_GetOutSettlement ;
      ELSIF(Cur_Parameter.ParameterName='CheckIsPaid') THEN
        -- SZ Obsolete
        RAISE NOTICE '%','  IsPaid=' || v_IsPaid ;
      ELSIF(Cur_Parameter.ParameterName='NewWriteOffAmt') THEN
        -- SZ Obsolete
        RAISE NOTICE '%','  WriteOffAmt=' || v_WriteOffAmt ;
      ELSE
        RAISE NOTICE '%','*** Unknown Parameter=' || Cur_Parameter.ParameterName ;
      END IF;
    END LOOP; --  Get Parameter
    RAISE NOTICE '%','  Record_ID=' || v_Record_ID ;
    /*
    *  Checking Restrictions
    */
    v_ResultStr:='CheckingRestrictions';
    SELECT COUNT(*)
    INTO v_Aux
    FROM C_Debt_Payment p
    WHERE p.C_Debt_Payment_ID=v_Record_ID
      AND C_DEBT_PAYMENT_STATUS(p.C_SETTLEMENT_CANCEL_ID, p.Cancel_Processed, p.Generate_Processed, p.IsPaid, p.IsValid, p.C_CashLine_ID, p.C_BankStatementLine_ID) IN('I', 'P') ;
    IF v_Aux=0 THEN
      RAISE EXCEPTION '%', '@DebtPaymentNotPending@'; --OBTG:-20000--
    END IF;
    IF(NOT FINISH_PROCESS) THEN
        UPDATE C_DEBT_PAYMENT
          SET UPDATED=TO_DATE(NOW()),
          UPDATEDBY=v_AD_User_ID,
          ISPAID='N',
          C_SETTLEMENT_CANCEL_ID=NULL,
          WRITEOFFAMT=0
        WHERE C_Debt_Payment_ID=v_Record_ID;
    END IF; --FINISH_PROCESS
    ---- <<FINISH_PROCESS>>
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'N', v_Result, v_Message) ;
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


SELECT zsse_dropfunction ('c_settlement_sepa_collect');
CREATE OR REPLACE FUNCTION c_settlement_sepa_collect(Pc_bankstatement_id character varying) returns varchar as $_$
/** SEPA-Basislastschriften generieren 11-08-2014
*   zu jeder Kontoauszugszeile (c_bankstatementline)
*   einen neuen Datensatz Geldverkehr (c_settlement) ausgeben,
*   den durch Rechnungstellung bereits erzeugten Datensatz Ford./Verb. (c_debt_payment) die Herkunft vermerken 
**/
 -- SELECT c_settlement_sepa_collect('8DDD9A18F3BA4335B0D121DD8E2EF33C'); -- template for excecution: c_bank
DECLARE 
  

BEGIN

   


if Pc_bankstatement_id is not null then
    -- The following code is creating a settlenment
    -- It was deactivated , we create Settlement when the real transaction against Bank is done
    /*
      UPDATE c_bankstatement 
      SET 
        sepacollectioniscreated = 'P'
      WHERE c_BankStatement_id = Pc_bankstatement_id;
      RAISE NOTICE '% %', 'UPDATE c_bankstatement:', 'c_bankstatement.sepacollectioniscreated=P / Process';
      PERFORM c_bankstatement_post(Pc_bankstatement_id);
    */
    UPDATE c_bankstatement 
      SET 
        sepacollectioniscreated = 'Y'
      WHERE c_BankStatement_id = Pc_bankstatement_id;
end if;

  RETURN 'OK';
END; $_$ LANGUAGE 'plpgsql' VOLATILE COST 100;



SELECT zsse_dropfunction ('c_settlement_sepa_revert');
CREATE OR REPLACE FUNCTION c_settlement_sepa_revert(p_PInstance_id character varying) returns void as $BODY$
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
Part of Projects, Begins a Project
Checks
*****************************************************/
v_Record_ID  character varying;
v_User    character varying;
v_message character varying:='Success';
Cur_AutomaticSettlementCancel RECORD;
v_org varchar;
v_ResultStr varchar;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    UPDATE c_bankstatement 
      SET 
        sepacollectioniscreated = 'N'
      WHERE c_BankStatement_id = v_Record_ID;
    --perform c_bankstatement_post(v_Record_ID);
    RAISE NOTICE '%','Updating PInstance - Finished ' || v_Message ;
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
  
  
  
  
  
  
CREATE OR REPLACE FUNCTION c_cashbook_trg() RETURNS trigger
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
    * $Id: C_Cashbook_Trg.sql,v 1.2 2002/01/02 04:53:50 jjanke Exp $
    ***
    * Title: New Accounting Defaults
    * Description:
    ************************************************************************/
    --TYPE RECORD IS REFCURSOR;
  Cur_Defaults RECORD;
  v_count numeric;  
BEGIN
    
    IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 
    END IF;


  IF (TG_OP = 'INSERT') THEN
    FOR Cur_Defaults IN
      (
      SELECT *
      FROM C_AcctSchema_Default d
      WHERE EXISTS
        (
      SELECT 1 
      FROM AD_Org_AcctSchema
      WHERE AD_IsOrgIncluded(AD_Org_ID, new.AD_ORG_ID, new.AD_Client_ID)<>-1
      AND IsActive = 'Y'
      AND AD_Org_AcctSchema.C_AcctSchema_ID = d.C_AcctSchema_ID
      UNION
      SELECT 1 
      FROM AD_Org_AcctSchema
      WHERE AD_Org_ID = '0'
      AND AD_Client_ID = new.AD_Client_ID
      AND IsActive = 'Y'
      AND AD_Org_AcctSchema.C_AcctSchema_ID = d.C_AcctSchema_ID
        )
      )
    LOOP
      INSERT
      INTO C_Cashbook_Acct
        (
          C_Cashbook_Acct_ID, C_Cashbook_ID, C_AcctSchema_ID, AD_Client_ID,
          AD_Org_ID, IsActive, Created,
          CreatedBy, Updated, UpdatedBy,
          CB_Asset_Acct, CB_Differences_Acct, CB_Expense_Acct,
          CB_Receipt_Acct, CB_CashTransfer_Acct
        )
        VALUES
        (
          get_uuid(), new.C_Cashbook_ID, Cur_Defaults.C_AcctSchema_ID, new.AD_Client_ID,
          new.AD_ORG_ID,  'Y', TO_DATE(NOW()),
          new.CreatedBy, TO_DATE(NOW()), new.UpdatedBy,
          Cur_Defaults.CB_Asset_Acct, Cur_Defaults.CB_Differences_Acct, Cur_Defaults.CB_Expense_Acct,
          Cur_Defaults.CB_Receipt_Acct, Cur_Defaults.CB_CashTransfer_Acct
        )
        ;
    END LOOP;
  ELSIF (TG_OP = 'UPDATE') THEN
    UPDATE C_CASHBOOK_ACCT SET AD_ORG_ID = new.AD_ORG_ID
    WHERE C_CASHBOOK_ID = new.C_CASHBOOK_ID;
  END IF;
  select count(*) into v_count from AD_Org_AcctSchema,C_AcctSchema where C_AcctSchema.C_AcctSchema_id=AD_Org_AcctSchema.C_AcctSchema_id
  and AD_Org_AcctSchema.ad_org_id=new.ad_org_id and C_AcctSchema.c_currency_id=new.c_currency_id;
  if v_count!=1 then
    raise exception '%', 'Kassenbücher werden zur Zeit nur in Buchwährung in einer Organisation unterstützt (kein * wählen)';
  end if;
IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; 

END; $_$;




CREATE OR REPLACE FUNCTION c_getaccountfromCash(p_cash_id character varying)
  RETURNS character varying AS
$_$
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
 v_acct varchar;
BEGIN
 
  select vc.alias into v_acct from c_cash c, c_cashbook cb,  c_cashbook_acct cba,  c_acctschema ac,ad_org_acctschema aco,c_validcombination vc
  where c.ad_org_id=aco.ad_org_id and aco.c_acctschema_id=ac.c_acctschema_id and cba.c_acctschema_id=ac.c_acctschema_id and cba.cb_asset_acct=vc.c_validcombination_id
  and cb.c_cashbook_id=cba.c_cashbook_id and  c.c_cashbook_id=cb.c_cashbook_id and c.c_cash_id=p_cash_id;
  RETURN v_acct; 

END;
$_$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION c_getaccountfromCashline(p_cashline_id character varying)
  RETURNS character varying AS
$_$
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
 v_acct varchar;
 v_product varchar;
 v_acctschema_id varchar;
 v_org varchar;
 v_retacct varchar;
BEGIN
  select i.m_product_id,i.ad_org_id into v_product,v_org from c_cashline cl,   c_debt_payment dp,c_invoiceline i 
        where cl.c_cashline_id=p_cashline_id and cl.c_debt_payment_id=dp.c_debt_payment_id and dp.c_invoice_id=i.c_invoice_id order by i.line limit 1;
  select c_acctschema_id into v_acctschema_id from ad_org_acctschema where ad_org_id=v_org;
  v_retacct:=zsfi_GetPAccount('2',v_product,v_acctschema_id);
  select vc.alias into v_acct from c_validcombination vc where vc.c_validcombination_id=v_retacct;
  RETURN v_acct; -- c_bp_bankaccount_id

END;
$_$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION C_DUNNING_STATUS(p_dunning_id varchar,p_lang varchar)
  RETURNS character varying AS
$_$
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
  select name into v_return from c_dunning_trl where c_dunning_id = p_dunning_id and ad_language = p_lang;
  if v_return is null then
    select name into v_return from c_dunning where c_dunning_id = p_dunning_id;
  end if;
  RETURN v_return;

END;
$_$ LANGUAGE plpgsql;


select zsse_dropfunction ('c_aging_get_scope');
CREATE OR REPLACE FUNCTION c_aging_get_scope(pplanneddate timestamp without time zone, ptrxdate timestamp without time zone, pcol1 numeric, pcol2 numeric, pcol3 numeric, pcol4 numeric) RETURNS numeric
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
* All portions are Copyright (C) 2008 Openbravo SL
* All Rights Reserved.
* Contributor(s): OpenZ Software GmbH , 2019
************************************************************************/
/*************************************************************************
* Description: This function is is similar to oracle's add_months function
*  In case the TIMESTAMP is i.e. 28/02/2007 this function will return 28/03/2007
*  while add_moths returns 31/03/2007
************************************************************************/
  pDateAux TIMESTAMP;
BEGIN
  if (pplanneddate>coalesce(ptrxdate,TO_DATE(NOW()))) then
    return 0;
  elsif (pplanneddate+pCol1>=coalesce(ptrxdate,TO_DATE(NOW()))) then
    return 1;
  elsif (pplanneddate+pCol2>=coalesce(ptrxdate,TO_DATE(NOW()))) then
    return 2;
  elsif (pplanneddate+pCol3>=coalesce(ptrxdate,TO_DATE(NOW()))) then
    return 3;
  elsif (pplanneddate+pCol4>=coalesce(ptrxdate,TO_DATE(NOW()))) then
    return 4;
  else
    return 5;
  end if;
END ; $_$;

