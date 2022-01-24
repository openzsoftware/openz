CREATE or replace FUNCTION zsdv_strNumber(v_num numeric, lang character varying) RETURNS character varying
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
Returns specific German Localization regardless of the localization of the machine
*****************************************************/
DECLARE
-- Simple Types
v_return  character varying;
v_ds varchar;
v_ts varchar;
BEGIN
  select coalesce(decimalseparator,','),coalesce(thousandseparator,'.') into v_ds,v_ts from ad_language where ad_language= lang;
      --return replace(to_char(v_num,'99999G990D99'),' ','');
      v_return:=replace(to_char(v_num, '999,999,999,999,990.99'),' ','');
      v_return:=replace(v_return,'.','X');
      v_return:=replace(v_return,',','');
      v_return:=replace(v_return,'X',v_ds);
      RETURN v_return;
END;
$_$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;



SELECT zsse_dropfunction('zsdv_insertDatevExport');
CREATE OR REPLACE FUNCTION zsdv_insertDatevExport(p_OrgID character varying,p_DateFrom character varying, p_DateTo character varying, p_user character varying,p_exuid character varying,  p_complete  character varying, p_allnew character varying, p_DateLaterThan character varying)
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
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Datev-Export
*****************************************************/
v_return       character varying;
v_count        numeric;
v_satz         character varying;
v_from        timestamp without time zone;
v_to          timestamp without time zone;
v_laterthan   timestamp without time zone;
v_client      character varying;
BEGIN

      v_from:=to_timestamp(p_DateFrom,'DD-MM-YYYY');
      v_to:=to_timestamp(p_DateTo,'DD-MM-YYYY');
      v_laterthan:=to_timestamp(p_DateLaterThan,'DD-MM-YYYY');
      select ad_client_id into v_client from ad_org where ad_org_id=p_OrgID;

      if coalesce(p_OrgID,'0')='0' then
          return 'Parameter Fehler. Es muß Organisation angegeben werden.';
      end if;

      if (p_DateFrom='' or p_DateTo='') then
         return 'Parameter Fehler. Es müssen Buchungsdatum von und Buchungsdatum bis angegeben werden.';
      end if;

      if  p_allnew='Y' and p_complete='Y' then
         return 'Parameter Fehler. "Kompletter Export" und "Nur neue Buchungssätze" widersprechen sich.';
      end if;
      
      if  p_allnew='N' and p_complete='N' then
         return 'Parameter Fehler. Eine Option muß ausgewählt sein: "Kompletter Export" oder "Nur neue Buchungssätze".';
      end if;
      if  p_allnew='Y' and p_DateLaterThan='' then
        return 'Parameter Fehler. Wenn  "Nur neue Buchungssätze" gewählt ist, muß auch "Buchung Erstellt ab" gefüllt sein.';
      end if;
      
      select count(*) into v_count from fact_acct where  dateacct between v_from and v_to  and ad_org_id=p_OrgID and
                                 case when p_complete='N' and p_allnew='Y' then trunc(created)>=v_laterthan ELSE 1=1 END;
      if v_count=0 then 
          RAISE EXCEPTION '%', 'Keine Daten zu exportieren';
      end if;
      -- Header schreiben
      insert into ZSDV_DATEV_EXPORT(ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,  date_from,date_to,filename, dateexp)
              values (p_exuid,v_client, p_OrgID,p_user,p_user,v_from,v_to,'Buchungssaetze'||to_char(now(),'ddmmyyyy-hh24:mi:ss')||'.csv',now());
      -- Header
      --OLD v_satz:='EingegWaehr;SollHaben;EingegUmsatz;BUFeld;Gegenkonto;Beleg1;Beleg2;Belegdatum;KtoNr;Kost1;Kost2;KostMenge;Skonto;BuchText;EULand_UstID;EUSteuersatz;WKZBasisUmsatz;BasisUmsatz;Kurs;InformationsArt1;Informationsinhalt1;InformationsArt2;Informationsinhalt2;InformationsArt3;Informationsinhalt3;InformationsArt4;Informationsinhalt4;InformationsArt5;Informationsinhalt5;InformationsArt6;Informationsinhalt6;InformationsArt7;Informationsinhalt7;InformationsArt8;Informationsinhalt8;InformationsArt9;Informationsinhalt9;InformationsArt10;Informationsinhalt10;InformationsArt11;Informationsinhalt11;InformationsArt12;Informationsinhalt12;InformationsArt13;Informationsinhalt13;InformationsArt14;Informationsinhalt14;InformationsArt15;Informationsinhalt15;InformationsArt16;Informationsinhalt16;InformationsArt17;Informationsinhalt17;InformationsArt18;Informationsinhalt18;InformationsArt19;Informationsinhalt19;InformationsArt20;Informationsinhalt20';
      v_satz:='    Umsatz;        SollHaben;WKZUmsatz;Kurs;Basisumsatz;WKZBasisumsatz;         Konto;    Gegenkonto;     BUSchluessel;                           Belegdatum;Belegfeld1        ;Belegfeld2        ;Skonto;Buchungstext;Postensperre;AdrNummer;GPBank;Sachverhalt;Zinssperre;Beleglink;BeleginfoArt1;BeleginfoInhalt1;BeleginfoArt2;BeleginfoInhalt2;BeleginfoArt3;BeleginfoInhalt3;BeleginfoArt4;BeleginfoInhalt4;BeleginfoArt5;BeleginfoInhalt5;BeleginfoArt6;BeleginfoInhalt6;BeleginfoArt7;BeleginfoInhalt7;BeleginfoArt8;BeleginfoInhalt8;Kost1;Kost2;KostMenge;USTID      ;EUSteuesatz;AbwSt;SachverhaltLuL;FunktionLuL;BU49Haupt;BU49No;BU49Erg;InformationsArt1;Informationsinhalt1;InformationsArt2;Informationsinhalt2;InformationsArt3;Informationsinhalt3;InformationsArt4;Informationsinhalt4;InformationsArt5;Informationsinhalt5;InformationsArt6;Informationsinhalt6;InformationsArt7;Informationsinhalt7;InformationsArt8;Informationsinhalt8;InformationsArt9;Informationsinhalt9;InformationsArt10;Informationsinhalt10;InformationsArt11;Informationsinhalt11;InformationsArt12;Informationsinhalt12;InformationsArt13;Informationsinhalt13;InformationsArt14;Informationsinhalt14;InformationsArt15;Informationsinhalt15;InformationsArt16;Informationsinhalt16;InformationsArt17;Informationsinhalt17;InformationsArt18;Informationsinhalt18;InformationsArt19;Informationsinhalt19;InformationsArt20;Informationsinhalt20;Stueck;Gew;Zahlw;ForderArt;VeranlJahr;ZugFaelligk;SkontTyp;Auftragsnummer;TRBuchungstyp;UstSchlANZ;EULandANZ;SachverhaltANZ;EUSteuerANZ;ErlösANZ;HerkuftKZ;Leerfeld;KostDATUM;SEPAMntd;Skontosperre;GesName;BeteilNo;IDNo;Zeichen;PostenSperreBis;SoBilSachv;SoBilBuchung;Festschreibung;Leistungsdatum;DatumZuordPeriode';
      --v_satz:=v_stramt||';'||v_shStz    ||';         ;    ;           ;              ;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00  ;'||v_desc||';            ;         ;      ;           ;          ;         ;             ;                ;             ;                ;             ;                ;             ;                ;             ;                ;             ;                ;             ;                ;             ;                ;     ;     ;         ;'||v_uid||';0,00       ;     ;              ;           ;         ;      ;       ;'||v_ziart1||'  ;'||v_ldesc||'      ;'||v_ziart2||'  ;'||v_ziart2text||';'||v_ziart3||'  ;'||v_ziart3text||';                ;                   ;                ;                   ;                ;                   ;                ;                   ;                ;                   ;                ;                   ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;                 ;                    ;      ;   ;     ;         ;          ;           ;        ;              ;             ;          ;         ;              ;           ;        ;         ;        ;         ;        ;            ;       ;        ;    ;       ;               ;          ;            ;'||v_fest||'  ;              ;                 ';
      v_satz:=replace(v_satz,' ','');
      insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group, lineno,export_data ) 
                        values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,null,null,1,v_satz);
     -- EXPORT-Routine
      v_return:=zsdv_insertDatevExportLINES(p_OrgID,v_from,v_to,p_user,p_exuid, p_complete,p_allnew,v_laterthan);
      return v_return;

end; $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;


SELECT zsse_dropfunction('zsdv_insertDatevExportLINES');
CREATE OR REPLACE FUNCTION zsdv_insertDatevExportLINES(p_OrgID character varying,p_DateFrom timestamp without time zone, p_DateTo timestamp without time zone, p_user character varying,p_exuid character varying,  p_complete  character varying, p_allnew character varying, p_DateLaterThan  timestamp without time zone)
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
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Datev-Export
*****************************************************/
v_count       numeric;
v_rcount      numeric:=0;
v_client      character varying;
v_source      character varying;
v_sollhaben   character varying;
v_onlydebcred character varying;
v_dracct      character varying;
v_cracct      character varying;
v_taxdracct   character varying;
v_taxcracct   character varying;
v_taxbooked   character varying;
v_desc        character varying;
v_ldesc       varchar;
v_ziart1      varchar:='Buchungstext';
v_ziart2      varchar:='KreditorDebitorNr';
v_ziart3      varchar:='Referenznummer';
v_ziart4      varchar:='Steuerart';
v_ziart5      varchar:='Projektname';
v_ziart6      varchar:='Projektaufgabe';
v_ziart2text       varchar:='';
v_ziart3text       varchar:='';
v_ziart4text       varchar:='';
v_ziart5text       varchar:='';
v_ziart6text       varchar:='';
v_satz        character varying;
v_stramt      character varying;
v_uid         character varying:='';
v_korrektur   character varying:='';
v_belegfeld1  character varying:=''; -- Rechnungsnummer
v_belegfeld2  character varying:=''; -- leer
v_kost1       varchar:=''; -- Je nach Konfig
v_kost2       varchar:=''; -- Je nach Konfig
v_kost1conf       varchar:=''; -- Konfig
v_kost2conf       varchar:=''; -- Konfig
v_tax         character varying;
v_usedatevkey varchar;
v_datevkeyvst varchar;
v_adtax       character varying;
v_adtaxINV    character varying:='';
v_revtax      character varying;
v_check       numeric;
v_amt         numeric;
v_vamt        numeric;
v_sourceamt   numeric;
v_i           numeric;
v_line        numeric:=1;
v_cur1        RECORD;
v_cur2        RECORD;
v_cur3        RECORD;
v_exporttype  character varying;
v_project     character varying;
v_costcenter  character varying;
v_lineid      varchar;
v_oldlineid   varchar;
v_newgroup varchar;
v_datevauto varchar;
v_datevkz40 varchar;
v_gegenkonto varchar;
v_gegenkontoID varchar;
v_taxacct varchar;
v_issotrx varchar;
v_xsource varchar;
v_shStz   varchar;
v_fest    varchar:='0';
v_mcount numeric;
BEGIN
      --select count(*) into v_count from c_periodcontrol_v where ad_org_id=p_OrgID and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=p_DateFrom and enddate>=p_DateFrom;
      --if v_count=0 then v_fest:='1'; end if;
      --select count(*) into v_count from c_periodcontrol_v where ad_org_id=p_OrgID and isactive='Y' and periodstatus='O' and docbasetype=v_docbasetype and startdate<=p_DateTo and enddate>=p_DateTo;
      --if v_count=0 then v_fest:='1'; end if;
      select o.ad_client_id,a.datevcost1,a.datevcost2 into v_client,v_kost1conf,v_kost2conf from ad_org o,ad_org_acctschema x,c_acctschema a where o.ad_org_id=x.ad_org_id and x.c_acctschema_id=a.c_acctschema_id and o.ad_org_id=p_OrgID;
      -- Normal DATEV-Export (Alles exportieren
      -- oder Nur Eingangs/Ausgangsrechnungen (Table 318)
      select c_getconfigoption('datevonlycreditdebit',p_OrgID) into v_onlydebcred;
      
      for v_cur1 in (select distinct fact_acct_group_id,ad_table_id,'N' as zeroinv,docbasetype from fact_acct where AD_ORG_ID=p_OrgID and 
                              dateacct between p_DateFrom and p_DateTo  and
                              case when p_complete='N' and p_allnew='Y' then trunc(created)>=p_DateLaterThan ELSE 1=1 END
                     union --- 0-Betrag: Rechnungen 2x losschicken
                     select distinct fact_acct_group_id,ad_table_id,'Y' as zeroinv,docbasetype from fact_acct where AD_ORG_ID=p_OrgID and 
                              dateacct between p_DateFrom and p_DateTo  and
                              case when p_complete='N' and p_allnew='Y' then trunc(created)>=p_DateLaterThan ELSE 1=1 END
                            and case when ad_table_id!='318' then 1=0 else
                                     not exists  (select 0 from fact_acct ff where ff.fact_acct_group_id=fact_acct.fact_acct_group_id
                                                                and ff.seqno=10) 
                                end
                    order by fact_acct_group_id)
      LOOP
          -- Kostenstelle, Project, Steuerart, RechnungsNo.
          /*
          800019 (C_Settlement) RechnungsNo., Ref. No.
          318    (C_Invoice) Kostenstelle, Project, Steuerart, RechnungsNo.
          800060 (A_Amortization) - NIX
          407    (C_Cash) -- NIX
          392    (C_BankStatement) -- NIX
          4AF9D81E51A04F2B987CD91AA9EE99F4 (zsfi_macctline) Kostenstelle, Project, Steuerart */
          
          select count(*) into v_count from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno=999999 and v_cur1.ad_table_id='800019';
          if v_count>0 and coalesce(v_onlydebcred,'N')='N' then 
              -- Zahlungsabgleich C_Settlement - 
              for v_cur2 in (select * from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno!=999999 and line_id is not null order by seqno)
              LOOP
                select count(*) into v_count from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno=999999 and line_id=v_cur2.line_id;
                if v_count!=1 then
                    RAISE EXCEPTION '%','Datev-Export-Fehler: Kein Gegenkonto definiert: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                end if;
                if v_cur2.amtacctdr!=0 then
                    v_sourceamt :=  v_cur2.amtacctdr;
                    v_dracct:=v_cur2.acctvalue;
                    select amtacctcr,acctvalue into v_amt,v_cracct from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno=999999 and line_id=v_cur2.line_id;
                elsif v_cur2.amtacctcr!=0 then
                    v_sourceamt :=  v_cur2.amtacctcr;
                    v_cracct:=v_cur2.acctvalue;
                    select amtacctdr,acctvalue into v_amt, v_dracct from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno=999999 and line_id=v_cur2.line_id;
                else
                      RAISE EXCEPTION '%','Datev-Export-Fehler: Kein Betrag gefunden: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                end if;
                v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                if v_cur2.c_bpartner_id is not null then
                    select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                else
                    v_ziart2text:='';
                end if;
                if v_amt < 0 then
                      v_sollhaben:='H';
                      v_amt:=v_amt*(-1);
                else
                      v_sollhaben:='S';
                end if;
                if abs(v_amt)!= abs(v_sourceamt) then
                    v_stramt:=zsdv_strNumber(least(v_amt,v_sourceamt),'de_DE');
                else
                    v_stramt:=zsdv_strNumber(v_amt,'de_DE');
                end if;
                -- OLD v_satz:= ';'||v_sollhaben||';'||v_stramt||';;'||v_dracct||';;;'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';;0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                v_shStz:=v_sollhaben;
                v_korrektur:='';
                v_uid:='';
                -- RechnungsNo., Ref No.
                select substr(i.documentno,1,12),i.poreference into  v_belegfeld1,v_ziart3text from c_invoice i,c_debt_payment p,c_settlement s where s.c_settlement_id=v_cur2.record_id 
                       and (p.c_settlement_cancel_id=s.c_settlement_id or p.c_settlement_generate_id=s.c_settlement_id) and i.c_invoice_id=p.c_invoice_id;
                if v_belegfeld1 is null then v_belegfeld1:=''; end if; if v_ziart3text is null then v_ziart3text:=''; end if; 
                v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                v_line:=v_line+1;
                if v_satz is null then
                   raise exception '%','Datensatz ist NULL a: '||v_cur2.fact_acct_id;
                end if;
                insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group, lineno,export_data )
                        values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                v_belegfeld1:='';
                v_ziart3text:='';
                -- Währungsdifferenzen ? - weden immer mit lineid=null in erster seq gebucht..
                -- AUFTEILUNG für Währungsdifferenzen 
                if (select count(*) from  fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno=v_cur2.seqno-10 and line_id is null)=1 then
                
                    select *  into v_cur3 from  fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno=v_cur2.seqno-10 and line_id is null;
                    if v_cur3.amtacctdr!=0 then
                        v_vamt :=  v_cur3.amtacctdr;
                        v_dracct:=v_cur3.acctvalue;
                    elsif v_cur3.amtacctcr!=0 then
                        v_vamt :=  v_cur3.amtacctcr;
                        v_cracct:=v_cur3.acctvalue;
                    end if;
                    if v_sourceamt< (case when v_sollhaben='H' then -1 else 1 end) * v_amt then
                        v_sourceamt := v_sourceamt + v_vamt;
                    end if;
                    if v_sourceamt> (case when v_sollhaben='H' then -1 else 1 end) * v_amt then
                        v_amt:=v_amt+(case when v_sollhaben='H' then -1 else 1 end) * v_vamt;
                    end if;
                    --raise exception '%', v_sourceamt||'#'||v_vamt||'#'||v_amt||'#'||v_cur3.amtacctdr||'#'||v_cur3.amtacctcr;
                    v_stramt:=zsdv_strNumber(v_vamt,'de_DE');
                    -- OLD v_satz:= ';'||v_sollhaben||';'||v_stramt||';;'||v_dracct||';;;'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';;0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                    v_shStz:=v_sollhaben;
                    v_korrektur:='';
                    v_uid:='';
                    v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                    insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group, lineno,export_data )
                        values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                end if;
                if abs(v_sourceamt)-abs(v_amt)!=0 then
                    RAISE EXCEPTION '%','Datev-Export-Fehler: Soll und Haben ungleich: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Erg:'||to_char(v_sourceamt)||' und '||to_char(v_amt)||' Key:'||v_cur2.fact_acct_group_id;
                end if;
                v_rcount:=v_rcount+1;
              END LOOP;
          elsif (v_cur1.ad_table_id='800060') and coalesce(v_onlydebcred,'N')='N'  then
              -- Amortization, Bank Statement
              v_i:=0;
              for v_cur2 in (select * from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id order by seqno)
              LOOP
                -- Bei Bank alterniert immer Bankkonto und Zwischenkonto, Bankkonto an Stelle 1 (v_i=0)
                if v_i=0 then
                    v_i:=1;
                    if v_cur2.amtacctdr!=0 then
                      v_sourceamt :=  v_cur2.amtacctdr;
                      v_dracct:=v_cur2.acctvalue;
                      v_source:='H';
                    elsif v_cur2.amtacctcr!=0 then
                      v_sourceamt :=  v_cur2.amtacctcr;
                      v_cracct:=v_cur2.acctvalue;
                      v_source:='S';  
                    else
                      RAISE EXCEPTION '%','Datev-Export-Fehler: Kein Betrag gefunden: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                    end if;
                else
                    v_i:=0;
                    if v_source='H' then
                      v_amt:=v_cur2.amtacctcr;
                      v_cracct:=v_cur2.acctvalue;
                    else
                      v_amt:=v_cur2.amtacctdr;
                      v_dracct:=v_cur2.acctvalue;
                    end if;
                    if v_sourceamt-v_amt!=0 then
                      RAISE EXCEPTION '%','Datev-Export-Fehler: Soll und Haben ungleich: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Erg:'||to_char(v_sourceamt-v_amt)||' Key:'||v_cur2.fact_acct_group_id;
                    end if;
                    v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                    v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                    if v_cur2.c_bpartner_id is not null then
                        select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                    else
                        v_ziart2text:='';
                    end if;
                    if v_amt < 0 then
                      v_sollhaben:='H';
                      v_amt:=v_amt*(-1);
                    else
                      v_sollhaben:='S';
                    end if;
                    v_stramt:=zsdv_strNumber(v_amt,'de_DE');
                    --OLD v_satz:= ';'||v_sollhaben||';'||v_stramt||';;'||v_dracct||';;;'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';;0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                    v_shStz:=v_sollhaben;
                    v_korrektur:='';
                    v_uid:='';
                    v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                    v_line:=v_line+1;
                    if v_satz is null then
                        raise exception '%','Datensatz ist NULL b: '||v_cur2.fact_acct_id;
                    end if;
                    insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                          values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                    v_rcount:=v_rcount+1;
                  end if;
              END LOOP;
           elsif v_cur1.ad_table_id='392' and v_onlydebcred='N' then
              -- Bei Bank alterniert immer Bankkonto und Zwischenkonto, Bankkonto an Stelle 1 
              -- Es kann aber vorkommen, daß mehrere Zeilen gegengebucht werden (Skonti, Nebenkosten des Geldverkehrs)
              -- line id hilft, die verschiedenen vorgänge zu unterscheiden..
              -- docbasetype='DPC'  -- Down Payment to cash sind Anzahlungsrechnungen, die laufen normal mit durch
              v_check:=0;
              v_oldlineid:='';
              for v_cur2 in (select * from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id 
                             and case when p_allnew='N' then dateacct between p_DateFrom and p_DateTo else 1=1 END order by seqno)
              LOOP
                -- Bei Automatikkonten wird die Steuerbuchung  unterdrückt. (Es müssen dann Erlöskonto und Erh. Anzahlung BEIDES Automatik sein !!
                -- Datev bucht Brutto Betrag selbst und läuft über Automatik
                select count(*) into v_count from c_elementvalue where datevuseauto='Y' and c_elementvalue_id in 
                               (select account_id from fact_acct where fact_acct_group_id = v_cur1.fact_acct_group_id);
                if  v_cur2.docbasetype='DPC' and v_count>0 and v_cur2.c_tax_id is not null then
                    -- Buchung unterdrücken
                    null;
                else
                    v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                    v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                    if v_cur2.c_bpartner_id is not null then
                        select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                    else
                        v_ziart2text:='';
                    end if;
                    if v_cur2.line_id!=v_oldlineid then
                        v_oldlineid:=v_cur2.line_id;
                        if v_cur2.amtacctdr!=0 then
                        v_sourceamt :=  v_cur2.amtacctdr;
                        v_dracct:=v_cur2.acctvalue;
                        v_source:='H';
                        elsif v_cur2.amtacctcr!=0 then
                        v_sourceamt :=  v_cur2.amtacctcr;
                        v_cracct:=v_cur2.acctvalue;
                        v_source:='S';  
                        else
                        RAISE EXCEPTION '%','Datev-Export-Fehler: Kein Betrag gefunden: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                        end if;
                        v_check:= v_check+v_sourceamt;
                    else
                        if v_source='S' then 
                        v_amt:= v_cur2.amtacctdr; 
                        v_dracct:=v_cur2.acctvalue;
                        else 
                        v_amt:= v_cur2.amtacctcr; 
                        v_cracct:=v_cur2.acctvalue;
                        end if;
                        if v_amt=0 then
                            RAISE EXCEPTION '%','Datev-Export-Fehler: Betrag = 0  - '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                        end if;
                        -- Bei minus: H/S vertauschen
                        if v_amt < 0 then
                            v_sollhaben:='H';
                            v_amt:=v_amt*(-1);
                        else
                            v_sollhaben:='S';
                        end if;
                        v_check:= v_check-v_amt;
                        v_stramt:=zsdv_strNumber(v_amt,'de_DE');
                        --OLD v_satz:= ';'||v_sollhaben||';'||v_stramt||';;'||v_dracct||';;;'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';;0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                        v_shStz:=v_sollhaben;
                        v_korrektur:='';
                        v_uid:='';
                        v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                        v_line:=v_line+1;
                        if v_satz is null then
                        raise exception '%','Datensatz ist NULL c: '||v_cur2.fact_acct_id;
                        end if;
                        insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                        values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                    end if;
                end if; -- docbasetype='DPC'
              END LOOP;
              if v_check!=0 then
                 RAISE EXCEPTION '%','Datev-Export-Fehler: Soll und Haben im Bankabgleich ungleich. Key:'||v_cur2.fact_acct_group_id;
              end if;
          elsif v_cur1.ad_table_id='407' and v_onlydebcred='N' then
              -- Bei Kasse sammelt dei Buchung alle einträge und bucht zusammen an kasse aus. - Einträge haben hier eine Line ID 
              -- Kasse wird immer positiv gebucht (soll oder haben)
              -- Umgekehrt als sonst steht die Kassenbuchung immer als letztes - Ohne line id.
              v_source:='S';
              v_check:=0;
              for v_cur2 in (select * from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id order by seqno desc)
              LOOP
                v_sollhaben:='S';
                v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                if v_cur2.c_bpartner_id is not null then
                    select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                else
                    v_ziart2text:='';
                end if;
                if v_cur2.line_id is null then
                    v_sourceamt :=  v_cur2.amtacctcr;
                    if v_sourceamt=0 then
                        -- Haben - Saldo (minus)
                        v_sourceamt :=  v_cur2.amtacctdr * (-1);
                    end if;
                    v_cracct:=v_cur2.acctvalue;
                    v_check:= v_check+v_sourceamt;
                else
                    v_amt:=v_cur2.amtacctdr;
                    v_dracct:=v_cur2.acctvalue;
                    if v_amt=0 then
                        v_amt:=v_cur2.amtacctcr;
                        v_sollhaben:='H';
                    end if;
                    if v_amt<0 then
                      v_amt:=v_amt*(-1);
                      if v_sollhaben='H' then
                        v_sollhaben:='S';
                      else
                        v_sollhaben:='H';
                      end if;
                    end if;
                    if v_sollhaben='H' then
                        v_check:= v_check+v_amt;
                    else
                        v_check:= v_check-v_amt;
                    end if;
                    v_stramt:=zsdv_strNumber(v_amt,'de_DE');
                    --OLD v_satz:= ';'||v_sollhaben||';'||v_stramt||';;'||v_dracct||';;;'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';;0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                    v_shStz:=v_sollhaben;
                    v_korrektur:='';
                    v_uid:='';
                    v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                    v_line:=v_line+1;
                    if v_satz is null then
                       raise exception '%','Datensatz ist NULL d: '||v_cur2.fact_acct_id;
                    end if;
                    insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                       values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
               end if;
              END LOOP;
              if v_check!=0 then
                 RAISE EXCEPTION '%','Datev-Export-Fehler: Soll und Haben im Kassenbuch ungleich. Key:'||v_cur2.fact_acct_group_id;
              end if;
          elsif v_cur1.ad_table_id='318' and v_cur1.docbasetype='DPR' then
          -- Verumsatzen von Anzahlungsrechnungen
              v_dracct:=null;
              v_cracct:=null;
              for v_cur2 in (select * from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id order by seqno)
              LOOP
                    -- Bei Automatikkonten mit Kennziffer -> Automatik ausschalten
                    v_korrektur:='';
                    select isdoccontrolled into v_datevkz40 from c_elementvalue where c_elementvalue_id=v_cur2.account_id;
                    if v_datevkz40='Y' then
                        v_korrektur:='40';
                    end if;                   
                    -- Bei Automatikkonten wird die Steuerbuchung  unterdrückt. (Es müssen dann Erlöskonto und Erh. Anzahlung BEIDES Automatik sein !!
                    -- Datev bucht Brutto Betrag selbst und läuft über Automatik
                    select count(*) into v_count from c_elementvalue where datevuseauto='Y' and c_elementvalue_id in 
                                    (select account_id from fact_acct where fact_acct_group_id = v_cur1.fact_acct_group_id);
                    if  v_count>0 and v_cur2.c_tax_id is not null then
                        -- Buchung unterdrücken
                        null;
                    else
                        v_sollhaben:='S';  
                        if v_cur2.amtacctdr!=0 then
                            v_amt :=  v_cur2.amtacctdr;
                            v_dracct:=v_cur2.acctvalue;
                        elsif v_cur2.amtacctcr!=0 then
                            v_amt :=  v_cur2.amtacctcr;
                            v_cracct:=v_cur2.acctvalue;
                        else
                            RAISE EXCEPTION '%','Datev-Export-Fehler: Kein Betrag gefunden: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                        end if;
                        v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                        v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                        if v_cur2.c_bpartner_id is not null then
                            select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                        else
                            v_ziart2text:='';
                        end if; 
                        -- Jeder 2. Datensatz wird gebucht , Prinzip: 1. Konto 2.Gegenkonto und los...
                        if v_dracct is not null and v_cracct is not null then
                             v_stramt:=zsdv_strNumber(v_amt,'de_DE');
                             v_shStz:=v_sollhaben;
                             if v_cur2.line_id is not null then
                                select substr(i.documentno,1,12),
                                        case when v_kost2conf='KOSTVALUE'  then substr(a.value,1,8) when v_kost2conf='PRJTASKSEQNO' then to_char(pt.seqno) else '' end,
                                        case when v_kost1conf='PROJECTVALUE' then substr(p.value,1,8) when v_kost1conf='KOSTVALUE' then substr(a.value,1,8) when v_kost1conf='PROJECTVALUEKOSTVALUE' then substr(coalesce(a.value,p.value),1,8) else '' end,
                                        substr(pt.name,1,210),i.poreference,t.name, substr(p.name,1,210)
                                        into  v_belegfeld1,v_kost2,v_kost1,v_ziart6text,v_ziart3text,v_ziart4text,v_ziart5text
                                        from c_invoice i ,c_tax t,c_invoiceline il left join a_asset a on a.a_asset_id=il.a_asset_id 
                                                                            left join c_project p on il.c_project_id=p.c_project_id 
                                                                            left join c_projecttask pt on pt.c_projecttask_id=il.c_projecttask_id 
                                        where i.c_invoice_id=il.c_invoice_id and il.c_tax_id=t.c_tax_id and il.c_invoiceline_id=v_cur2.line_id;
                             else
                                select substr(i.documentno,1,12),i.poreference,t.name into  v_belegfeld1,v_ziart3text,v_ziart4text
                                    from c_invoice i ,c_tax t
                                    where  t.c_tax_id=v_cur2.c_tax_id and i.c_invoice_id=v_cur2.record_id;
                             end if;
                             if v_belegfeld1 is null then v_belegfeld1:=''; end if; if v_kost2 is null then v_kost2:=''; end if; if v_kost1 is null then v_kost1:=''; end if; if v_belegfeld2 is null then v_belegfeld2:=''; end if; if v_ziart3text is null then v_ziart3text:=''; end if; if v_ziart4text is null then v_ziart4text:=''; end if; if v_ziart5text is null then v_ziart5text:=''; end if; if v_ziart6text is null then v_ziart6text:=''; end if; 
                             v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||coalesce(v_cur2.uidnumber,'')||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                             v_line:=v_line+1;
                             if v_satz is null then
                                raise exception '%','Datensatz ist NULL UAZ: '||v_cur2.fact_acct_id;
                             end if;
                             insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                                    values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                            v_rcount:=v_rcount+1;
                            v_dracct:=null;
                            v_cracct:=null;
                            v_belegfeld1:=''; v_kost2:='';v_kost1:='';v_belegfeld2:='';v_ziart3text:='';v_ziart4text:='';v_ziart5text:='';v_ziart6text:='';
                        end if;
                        v_korrektur:='';
                    end if;
              END LOOP; -- Verumsatzen von Anzahlungsrechnungen END
          -- Table_id
          else
              v_taxbooked:='N';
              v_korrektur:='';
              v_lineid:='';
              v_oldlineid:='';
              v_newgroup:='N';
              v_datevkeyvst:=null;
              v_usedatevkey:='N';
              -- Tables sind Invoice, Manueller B-Stapel and Settlememnt ohne line 99999 (Das sind Abschreibungen mit Aufteilungen). Letztere werden über die line_id gefiltert, nicht über die Seq.-No.
              --  for v_cur2 in (select * from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id 
              --                          and case when coalesce(v_onlydebcred,'N')='Y' then fact_acct.ad_table_id='318' else 1=1 end order by seqno)
              --  zeroinv: Erweiterung für Rechnungen mit Summe =0
              for v_cur2 in (select ad_table_id,record_id,line_id,amtacctdr,amtacctcr,acctvalue,fact_acct_group_id,dateacct,description,c_bpartner_id,fact_acct_id,
                                      account_id,c_tax_id,seqno,uidnumber,c_acctschema_id
                                   from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id 
                                        and case when coalesce(v_onlydebcred,'N')='Y' then ad_table_id='318' else 1=1 end 
                                        and case when ad_table_id='318' then 
                                                 exists (select 0 from fact_acct ff where ff.fact_acct_group_id=fact_acct.fact_acct_group_id
                                                                and ff.seqno=10) 
                                                 else 1=1 end

                               union
                               select f.ad_table_id,f.record_id,get_uuid() as line_id,sum(f.amtacctcr) as amtacctdr,sum(f.amtacctdr) as amtacctcr,
                                      e.value as acctvalue,
                                      f.fact_acct_group_id,f.dateacct,
                                      i.documentno||' # '||b.name as description,f.c_bpartner_id,get_uuid() as fact_acct_id,
                                      e.c_elementvalue_id as account_id,
                                      f.c_tax_id,10 as seqno,f.uidnumber,f.c_acctschema_id
                                   from fact_acct f,c_invoice i,c_bpartner b,c_validcombination v,c_elementvalue e
                                      where f.record_id=i.c_invoice_id and f.c_bpartner_id=b.c_bpartner_id and v.c_acctschema_id=f.c_acctschema_id and
                                      v.account_id=e.c_elementvalue_id  and
                                      f.fact_acct_group_id=v_cur1.fact_acct_group_id and ad_table_id='318' and
                                      case when v_cur1.zeroinv='N' then f.amtacctdr>=0 and f.amtacctcr>=0 else  f.amtacctdr<=0 and f.amtacctcr<=0 end and
                                      not exists (select 0 from fact_acct ff where ff.fact_acct_group_id=f.fact_acct_group_id
                                                                and ff.seqno=10) 
                                      and v.c_validcombination_id=zsfi_GetBPAccount(case when i.issotrx='Y' then '1' else '2' end,f.c_bpartner_id,f.c_acctschema_id)
                                      group by f.ad_table_id,f.record_id,e.value,f.fact_acct_group_id,f.dateacct,i.documentno,b.name,f.c_bpartner_id,e.c_elementvalue_id,
                                               f.c_tax_id,f.uidnumber,f.c_acctschema_id
                               union
                               select ad_table_id,record_id,line_id,amtacctdr,amtacctcr,acctvalue,fact_acct_group_id,dateacct,description,c_bpartner_id,fact_acct_id,
                                      account_id,c_tax_id,seqno,uidnumber,c_acctschema_id
                                   from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and ad_table_id='318' and
                                      case when v_cur1.zeroinv='N' then amtacctdr>=0 and amtacctcr>=0 else  amtacctdr<=0 and amtacctcr<=0 end  and
                                      not exists (select 0 from fact_acct ff where ff.fact_acct_group_id=fact_acct.fact_acct_group_id
                                                                and ff.seqno=10) 
                               
                               order by seqno
                )
                LOOP
                    if v_cur2.ad_table_id='318' then
                        if v_cur2.line_id is not null then
                            select substr(i.documentno,1,12),
                                case when v_kost2conf='KOSTVALUE'  then substr(a.value,1,8) when v_kost2conf='PRJTASKSEQNO' then to_char(pt.seqno) else '' end,
                                case when v_kost1conf='PROJECTVALUE' then substr(p.value,1,8) when v_kost1conf='KOSTVALUE' then substr(a.value,1,8) when v_kost1conf='PROJECTVALUEKOSTVALUE' then substr(coalesce(a.value,p.value),1,8) else '' end,
                                substr(pt.name,1,210),i.poreference,t.name,substr(p.name,1,210)
                                into  v_belegfeld1,v_kost2,v_kost1,v_ziart6text,v_ziart3text,v_ziart4text,v_ziart5text
                                from c_invoice i ,c_invoiceline il left join a_asset a on a.a_asset_id=il.a_asset_id 
                                                                    left join c_project p on il.c_project_id=p.c_project_id 
                                                                    left join c_projecttask pt on pt.c_projecttask_id=il.c_projecttask_id 
                                                                    left join c_tax t on il.c_tax_id=t.c_tax_id
                                where i.c_invoice_id=il.c_invoice_id and il.c_invoiceline_id=v_cur2.line_id;
                        else
                            select substr(i.documentno,1,12),i.poreference,t.name into  v_belegfeld1,v_ziart3text,v_ziart4text
                            from c_invoice i ,c_tax t
                            where  t.c_tax_id=v_cur2.c_tax_id and i.c_invoice_id=v_cur2.record_id;
                        end if;
                    end if;
                    if v_cur2.ad_table_id='4AF9D81E51A04F2B987CD91AA9EE99F4' then
                        if v_cur2.c_tax_id is null then
                            select case when v_kost2conf='KOSTVALUE'  then substr(a.value,1,8) when v_kost2conf='PRJTASKSEQNO' then to_char(pt.seqno) else '' end,
                                   case when v_kost1conf='PROJECTVALUE' then substr(p.value,1,8) when v_kost1conf='KOSTVALUE' then substr(a.value,1,8) when v_kost1conf='PROJECTVALUEKOSTVALUE' then substr(coalesce(a.value,p.value),1,8) else '' end,
                                   substr(pt.name,1,210),substr(p.name,1,210) 
                            into  v_kost2,v_kost1,v_ziart6text,v_ziart5text
                            from zsfi_macctline g left join a_asset a on a.a_asset_id=g.a_asset_id
                                                left join c_project p on g.c_project_id=p.c_project_id 
                                                left join c_projecttask pt on pt.c_projecttask_id=g.c_projecttask_id 
                            where g.zsfi_macctline_id=v_cur2.record_id;
                        else
                            select t.name into  v_ziart4text from c_tax t where  t.c_tax_id=v_cur2.c_tax_id;
                        end if;
                    end if;
                    if v_belegfeld1 is null then v_belegfeld1:=''; end if; if v_kost2 is null then v_kost2:=''; end if; if v_kost1 is null then v_kost1:=''; end if; if v_belegfeld2 is null then v_belegfeld2:=''; end if; if v_ziart3text is null then v_ziart3text:=''; end if; if v_ziart4text is null then v_ziart4text:=''; end if;if v_ziart5text is null then v_ziart5text:=''; end if;if v_ziart6text is null then v_ziart6text:=''; end if;   
                    -- Settlement-Aufteilung (Abschreibung)
                    if v_cur2.ad_table_id='800019' then
                        v_lineid:=v_cur2.line_id;
                        if v_lineid!=v_oldlineid then
                           v_newgroup:='Y';
                        end if;
                        v_oldlineid:=v_lineid;
                        -- Datev bucht Brutto Betrag selbst und läuft über Automatik
                        select count(*) into v_count from c_elementvalue where datevuseauto='Y' and c_elementvalue_id in 
                                        (select account_id from fact_acct where fact_acct_group_id = v_cur1.fact_acct_group_id);
                        if v_count>0 and v_newgroup='Y' then
                            v_newgroup:='N';
                            if v_cur2.amtacctdr!=0 then
                                v_sourceamt :=  v_cur2.amtacctdr;
                                v_source:='H';
                                v_dracct:=v_cur2.acctvalue;
                            elsif v_cur2.amtacctcr!=0 then
                                v_sourceamt :=  v_cur2.amtacctcr;
                                v_source:='S';  
                                v_cracct:=v_cur2.acctvalue;
                            else
                                RAISE EXCEPTION '%','Datev-Export-Fehler: Kein Betrag gefunden: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                            end if;
                            select acctvalue,account_id into v_gegenkonto,v_gegenkontoID from fact_acct where  fact_acct_group_id=v_cur1.fact_acct_group_id 
                                                               and exists (select 0 from c_elementvalue where datevuseauto='Y' and c_elementvalue_id=account_id);
                            if v_source='H' then
                                v_cracct:=v_gegenkonto;
                            else
                                v_dracct:=v_gegenkonto;
                            end if;
                            -- Wenn auf SEQ=10 (erster , sprich Brutto Eintrag) gebucht wird, soll und haben umdrehen!!
                            if v_source='H' then
                                v_source:='S';  
                            end if;
                            --perform logg('amt:'||v_sourceamt||'-SR:'||v_source||'-KEY:'||coalesce(v_datevkeyvst,'AUTO')||v_cur2.description);
                            if v_sourceamt < 0 then
                                if v_source='H' then
                                    v_source:='S';  
                                else
                                    v_source:='H';
                                end if;
                                v_sourceamt:=v_sourceamt*(-1);
                            end if;
                            -- UST ID im Buchungssatz bei Skonto auf Zahlungen
                            if v_cur2.ad_table_id='800019' then
                                select count(*) into v_mcount from c_tax_acct c,c_tax t,c_validcombination w where 
                                        (w.c_validcombination_id=c.t_ar_discount_acct or w.c_validcombination_id=c.t_ap_discount_acct)
                                        and w.account_id=v_gegenkontoID
                                        and c.c_tax_id=t.c_tax_id and t.adduid2fact='Y';
                                if v_mcount>0 
                                then
                                    v_uid:=coalesce(v_cur2.uidnumber,'');
                                else
                                    v_uid:='';
                                end if;
                            end if;
                            v_stramt:=zsdv_strNumber(v_sourceamt,'de_DE');
                            v_line:=v_line+1;
                            v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            if v_cur2.c_bpartner_id is not null then
                                select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                            else
                                v_ziart2text:='';
                            end if;
                            --OLD v_satz:= ';'||v_source||';'||v_stramt||';'||v_korrektur||';'||v_dracct||';'||v_belegfeld1||';'||v_belegfeld2||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';'||v_uid||';0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                            v_shStz:=v_source;
                            v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                            if v_satz is null then
                                raise exception '%','Datensatz ist NULL e: '||v_cur2.fact_acct_id;
                            end if;
                            insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                                values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                            v_rcount:=v_rcount+1;
                            v_korrektur:='';
                            v_check:=0;
                            v_belegfeld1:=''; v_kost2:='';v_kost1:='';v_belegfeld2:='';v_ziart3text:='';v_ziart4text:='';v_ziart5text:='';v_ziart6text:='';
                            EXIT;
                        end if;
                    else        
                    -- Invoice, Manual Acct
                        v_lineid:='';
                    end if;
                    -- Bei Automatikkonten -> Automatik ausschalten
                    select isdoccontrolled into v_datevkz40 from c_elementvalue where c_elementvalue_id=v_cur2.account_id;
                    if v_datevkz40='Y' then
                        v_korrektur:='40';
                    end if;                   
                    -- UST ID im Buchungssatz bei Ausgangsrechnungen
                    if v_cur2.ad_table_id='318' then
                        select t.adduid2fact into v_adtaxINV from c_tax t,c_invoiceline il 
                        where il.c_tax_id=t.c_tax_id and il.c_invoiceline_id in 
                        (select line_id from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and c_tax_id is null) limit 1;
                    end if;
                    if (v_cur2.seqno=10  or (v_lineid!='' and v_newgroup='Y')) then
                        v_check:=0;
                        v_newgroup:='N';
                        if v_cur2.amtacctdr!=0 then
                            v_sourceamt :=  v_cur2.amtacctdr;
                            v_source:='H';
                            v_dracct:=v_cur2.acctvalue;
                        elsif v_cur2.amtacctcr!=0 then
                            v_sourceamt :=  v_cur2.amtacctcr;
                            v_source:='S';  
                            v_cracct:=v_cur2.acctvalue;
                        else
                            RAISE EXCEPTION '%','Datev-Export-Fehler: Kein Betrag gefunden: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                        end if;
                        v_check:= v_sourceamt;
                        select count(distinct c_tax_id) into v_count from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id ;
                        if v_count=1 then
                            -- EU Steuersätze - Ein kompletter Buchungssatz wird zusätzlich erzeugt. (Nur Bei Rechnungen-Vorsteuer wird sofort gezogen, Abschreibungen haben normale Aufteilung)
                            select c_tax_id into v_tax from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and c_tax_id is not null;
                            select adduid2fact,reversecharge into  v_adtax,v_revtax from c_tax where c_tax_id=v_tax;
                        else
                            v_adtax:='N';
                            v_revtax:='N';
                        end if;
                        if coalesce(v_adtax,'')='Y' or v_adtaxINV='Y'  then
                            v_uid:=coalesce(v_cur2.uidnumber,'');
                        else
                            v_uid:='';
                        end if;
                        -- Datev bucht Brutto Betrag selbst und läuft über Automatik
                        select count(*) into v_count from c_elementvalue where datevuseauto='Y' and c_elementvalue_id in 
                                        (select account_id from fact_acct where fact_acct_group_id = v_cur1.fact_acct_group_id);
                        if v_cur2.ad_table_id='318' then
                            select t.datevkeyvst,t.isnotaxable  into  v_datevkeyvst,v_usedatevkey from fact_acct f,c_tax t 
                                   where t.c_tax_id=f.c_tax_id and f.fact_acct_group_id=v_cur1.fact_acct_group_id limit 1;
                        end if;
                        --- Buchung auf Automatikkonto !!!
                        if (v_count>0 or (v_usedatevkey='Y' and v_datevkeyvst is not null)) 
                            and v_korrektur!='40' and  (v_cur2.ad_table_id='318' or v_cur2.ad_table_id='4AF9D81E51A04F2B987CD91AA9EE99F4') 
                        then
                            if v_count=0 then
                                v_korrektur:=v_datevkeyvst;
                            end if;
                            select count(distinct account_id) into v_count from fact_acct where  fact_acct_group_id=v_cur1.fact_acct_group_id and fact_acct_id!=v_cur2.fact_acct_id
                            and c_tax_id is null;
                            if v_count!=1 and v_cur2.ad_table_id='318' then
                                -- Hier erweitern wir, damit das alte Verhalten ansonsten bleibt...(s. Exept. Texte)
                                --RAISE EXCEPTION '%','Datev-Export-Fehler: Auf Automatikkonten kann nur eine Steuerart und ein Gegenkonto benutzt werden: '||v_cur2.description||'-'||v_cur1.fact_acct_group_id;
                                for v_cur3 in (select sum(f.amtacctdr) as amtacctdr, sum(f.amtacctcr) as amtacctcr,
                                               coalesce(f.c_tax_id,i.c_tax_id) as c_tax_id
                                               from fact_acct f left join c_invoiceline i on i.c_invoiceline_id=f.line_id
                                               where  fact_acct_group_id=v_cur1.fact_acct_group_id and coalesce(f.c_tax_id,i.c_tax_id) is not null 
                                               group by coalesce(f.c_tax_id,i.c_tax_id))
                                LOOP
                                    -- Setzen des Betrages
                                    if v_cur3.amtacctdr!=0 then
                                        v_sourceamt :=  v_cur3.amtacctdr;
                                    elsif v_cur3.amtacctcr!=0 then
                                        v_sourceamt :=  v_cur3.amtacctcr;
                                    end if;
                                    v_check:= v_sourceamt;
                                    -- Suchen des Gegenkontos (Automatik-Kontos)
                                    select issotrx into v_issotrx from c_invoice where c_invoice_id=v_cur2.record_id;
                                    if v_issotrx='N' then
                                    select v.account_id into v_taxacct from c_validcombination v,c_tax_acct t where t.c_acctschema_id=v_cur2.c_acctschema_id
                                               and t.t_credit_acct=v.c_validcombination_id and t.c_tax_id= v_cur3.c_tax_id;
                                    else
                                        select v.account_id into v_taxacct from c_validcombination v,c_tax_acct t where t.c_acctschema_id=v_cur2.c_acctschema_id
                                               and t.t_due_acct=v.c_validcombination_id and t.c_tax_id= v_cur3.c_tax_id;
                                    end if;
                                    select count(distinct account_id) into v_count from fact_acct where  fact_acct_group_id=v_cur1.fact_acct_group_id and 
                                           coalesce(c_tax_id,(select c_tax_id from c_invoiceline where c_invoiceline_id=line_id))=v_cur3.c_tax_id
                                           and account_id!=v_taxacct;
                                    if v_count!=1 then
                                        -- v_count||'#'||v_taxacct||'#'||v_cur3.c_tax_id||'#'||v_cur1.fact_acct_group_id||
                                        RAISE EXCEPTION '%','Datev-Export-Fehler: Auf Automatikkonten kann nur ein Gegenkonto pro Steuerart benutzt werden: '||v_cur2.description||'-'||v_cur1.fact_acct_group_id;
                                    end if;
                                    select acctvalue into v_gegenkonto from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and 
                                           coalesce(c_tax_id,(select c_tax_id from c_invoiceline where c_invoiceline_id=line_id))=v_cur3.c_tax_id
                                           and account_id!=v_taxacct and  fact_acct_id!=v_cur2.fact_acct_id;
                                    -- Buchungssatz erzeugen (wie im Orig. Code)
                                    if v_source='H' then
                                        v_cracct:=v_gegenkonto;
                                    else
                                        v_dracct:=v_gegenkonto;
                                    end if;
                                    -- Wenn auf SEQ=10 (erster , sprich Brutto Eintrag) gebucht wird, soll und haben umdrehen!!
                                    v_xsource:=v_source;
                                    if v_source='H' then
                                        v_xsource:='S';  
                                    end if;
                                    if v_sourceamt < 0 then
                                        if v_source='H' then
                                            v_xsource:='S';  
                                        else
                                            v_xsource:='H';
                                        end if;
                                        v_sourceamt:=v_sourceamt*(-1);
                                    end if;
                                    v_stramt:=zsdv_strNumber(v_sourceamt,'de_DE');
                                    v_line:=v_line+1;
                                    v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                                    v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                                    if v_cur2.c_bpartner_id is not null then
                                        select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                                    else
                                        v_ziart2text:='';
                                    end if;
                                    --OLD v_satz:= ';'||v_xsource||';'||v_stramt||';'||v_korrektur||';'||v_dracct||';'||v_belegfeld1||';'||v_belegfeld2||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';'||v_uid||';0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                                    v_shStz:=v_xsource;
                                    v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                                    if v_satz is null then
                                        raise exception '%','Datensatz ist NULL e: '||v_cur2.fact_acct_id;
                                    end if;
                                    insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                                        values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                                    v_rcount:=v_rcount+1;
                                    v_korrektur:='';
                                    v_check:=0;
                                END LOOP;
                                v_belegfeld1:=''; v_kost2:='';v_kost1:='';v_belegfeld2:='';v_ziart3text:='';v_ziart4text:='';v_ziart5text:='';v_ziart6text:='';
                                EXIT; -- cur3
                                --    raise exception '%',v_cur1.fact_acct_group_id||'#'||v_cur2.fact_acct_id||'#';
                            end if;
                            select acctvalue into v_gegenkonto from fact_acct where  fact_acct_group_id=v_cur1.fact_acct_group_id and fact_acct_id!=v_cur2.fact_acct_id and c_tax_id is null;
                            if v_source='H' then
                                v_cracct:=v_gegenkonto;
                            else
                                v_dracct:=v_gegenkonto;
                            end if;
                            -- Wenn auf SEQ=10 (erster , sprich Brutto Eintrag) gebucht wird, soll und haben umdrehen!!
                            if v_source='H' then
                                v_source:='S';  
                            end if;
                            --perform logg('amt:'||v_sourceamt||'-SR:'||v_source||'-KEY:'||coalesce(v_datevkeyvst,'AUTO')||v_cur2.description);
                            if v_sourceamt < 0 then
                                if v_source='H' then
                                    v_source:='S';  
                                else
                                    v_source:='H';
                                end if;
                                v_sourceamt:=v_sourceamt*(-1);
                            end if;
                            v_stramt:=zsdv_strNumber(v_sourceamt,'de_DE');
                            v_line:=v_line+1;
                            v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            if v_cur2.c_bpartner_id is not null then
                                select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                            else
                                v_ziart2text:='';
                            end if;
                            --OLD v_satz:= ';'||v_source||';'||v_stramt||';'||v_korrektur||';'||v_dracct||';'||v_belegfeld1||';'||v_belegfeld2||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';'||v_uid||';0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                            v_shStz:=v_source;
                            v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                            if v_satz is null then
                                raise exception '%','Datensatz ist NULL ef: '||v_cur2.fact_acct_id;
                            end if;
                            insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                                values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                            v_rcount:=v_rcount+1;
                            v_korrektur:='';
                            v_check:=0;
                            v_belegfeld1:=''; v_kost2:='';v_kost1:='';v_belegfeld2:='';v_ziart3text:='';v_ziart4text:='';v_ziart5text:='';v_ziart6text:='';
                            EXIT; -- cur2
                        end if; -- --- Buchung auf Automatikkonto
                    --seqno=10
                    elsif coalesce(v_revtax,'')='Y' and v_cur2.c_tax_id is not null then  
                        -- Reverse-Charge of TAX - Always one FACT - In einer Zeile Vorsteuer und gleichzeitig Vorsteuerabzug
                        -- Bezug von Waren und DL aus der EU
                        -- Bau (13b)-Leistungen Eingangsrechnung.
                        if v_taxbooked='N' then
                            select amtacctcr,acctvalue into v_amt,v_taxcracct from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and c_tax_id is not null and amtacctcr!=0;
                            select acctvalue,amtacctdr into v_taxdracct,v_vamt from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and c_tax_id is not null and amtacctdr!=0;
                            if v_amt!=v_vamt then
                            RAISE EXCEPTION '%','Datev-Export-Fehler: Soll und Haben ungleich: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Erg:'||to_char(v_amt)||' Key:'||v_cur2.fact_acct_group_id;
                            end if;
                            if v_amt < 0 then
                            v_sollhaben:='H';
                            v_amt:=v_amt*(-1);
                            else
                            v_sollhaben:='S';
                            end if;
                            v_stramt:=zsdv_strNumber(v_amt,'de_DE');
                            v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            if v_cur2.c_bpartner_id is not null then
                                select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                            else
                                v_ziart2text:='';
                            end if;
                            v_line:=v_line+1;
                            --raise notice '%','CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'||coalesce(v_taxdracct,'______O_____')||coalesce(v_taxcracct,'_____K______')||coalesce(v_desc,'____M_______')||coalesce(v_uid,'____B_______');
                            --OLD v_satz:= ';'||v_sollhaben||';'||v_stramt||';;'||v_taxdracct||';;;'||to_char(v_cur2.dateacct,'DDMM')||';'||v_taxcracct||';;;;0,00;'||v_desc||';'||v_uid||';0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                            v_shStz:=v_sollhaben;
                            -- Be arware of TAX-ACCOUNTS!!!
                            v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_taxcracct||';'||v_taxdracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                            if v_satz is null then
                                raise exception '%','Datensatz ist NULL f: '||v_cur2.fact_acct_id||'-'||v_cur1.fact_acct_group_id;
                            end if;
                            insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                                values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                            v_rcount:=v_rcount+1;
                            v_belegfeld1:=''; v_kost2:='';v_kost1:='';v_belegfeld2:='';v_ziart3text:='';v_ziart4text:='';v_ziart5text:='';v_ziart6text:='';
                        end if; 
                        v_taxbooked='Y';
                        -- Reverse-Charge of TAX - Always one FACT
                    else
                        -- Normale Aufteilungen
                        if v_source='S' then 
                            v_amt:= v_cur2.amtacctdr; 
                            v_dracct:=v_cur2.acctvalue;
                        else 
                            v_amt:= v_cur2.amtacctcr; 
                            v_cracct:=v_cur2.acctvalue;
                        end if;
                        v_check:= v_check-v_amt;
                        -- Währungsumrechnungen - Rundungsdifferenzen
                        if v_cur2.seqno=999998 and v_cur2.ad_table_id='318' and v_amt=0 then
                           if v_cur2.amtacctdr!=0 then v_amt:= v_cur2.amtacctdr; else v_amt:= v_cur2.amtacctcr; end if;
                           v_check:= v_check+v_amt;
                        end if;
                        if v_amt=0 then
                            -- Fehlerkorrekturen (Fehlbuchungen) werden immer mit Zeile 10 ausgeglichen - sollte es nicht geben.
                            select count(*) into v_count from fact_acct where fact_acct_group_id=v_cur1.fact_acct_group_id and seqno=10;
                            if v_count>1 then
                                RAISE EXCEPTION '%','Es liegen Fehlbuchungen vor. Bitte korrigieren  - '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                            else
                                RAISE EXCEPTION '%','Datev-Export-Fehler: Betrag = 0  - '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Key:'||v_cur2.fact_acct_group_id;
                            end if;
                        else
                            v_desc:=replace(replace(replace(replace(substr(v_cur2.description,1,60),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            v_ldesc:=replace(replace(replace(replace(substr(v_cur2.description,1,210),E'\r\n',''),';',''),chr(13),''),chr(10),'');
                            if v_cur2.c_bpartner_id is not null then
                                select value into v_ziart2text from c_bpartner where c_bpartner_id=v_cur2.c_bpartner_id;
                            else
                                v_ziart2text:='';
                            end if;
                            -- @TODO: Projekt und Kostenstelle
                            -- Bei minus: H/S vertauschen
                            if v_amt < 0 then
                                v_sollhaben:='H';
                                v_amt:=v_amt*(-1);
                            else
                                v_sollhaben:='S';
                            end if;
                            v_stramt:=zsdv_strNumber(v_amt,'de_DE');
                            -- UST ID im Buchungssatz bei Skonto auf Zahlungen
                            if v_cur2.ad_table_id='800019' then
                                select count(*) into v_mcount from c_tax_acct c,c_tax t,c_validcombination w where 
                                        (w.c_validcombination_id=c.t_ar_discount_acct or w.c_validcombination_id=c.t_ap_discount_acct)
                                        and w.account_id=v_cur2.account_id
                                        and c.c_tax_id=t.c_tax_id and t.adduid2fact='Y';
                                if v_mcount>0 
                                then
                                    v_uid:=coalesce(v_cur2.uidnumber,'');
                                else
                                    v_uid:='';
                                end if;
                            end if;
                            -- Bei Umsätzen auf Umsatzkonten - Steuerschlüssel 40 (Automatikbuchung im Datev abschalten)
                            --OLD v_satz:= ';'||v_sollhaben||';'||v_stramt||';'||v_korrektur||';'||v_dracct||';'||v_belegfeld1||';'||v_belegfeld2||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_cracct||';;;;0,00;'||v_desc||';'||v_uid||';0,00;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;';
                            v_shStz:=v_sollhaben;
                            v_satz:=v_stramt||';'||v_shStz||';;;;;'||v_cracct||';'||v_dracct||';'||v_korrektur||';'||to_char(v_cur2.dateacct,'DDMM')||';'||v_belegfeld1||';'||v_belegfeld2||';0,00;'||v_desc||';;;;;;;;;;;;;;;;;;;;;;;'||v_kost1||';'||v_kost2||';;'||v_uid||';0,00;;;;;;;'||v_ziart1||';'||v_ldesc||';'||v_ziart2||';'||v_ziart2text||';'||v_ziart3||';'||v_ziart3text||';'||v_ziart4||';'||v_ziart4text||';'||v_ziart5||';'||v_ziart5text||';'||v_ziart6||';'||v_ziart6text||';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'||v_fest||';;';
                            v_line:=v_line+1;
                            if v_satz is null then
                            raise exception '%','Datensatz ist NULL g: '||v_cur2.fact_acct_id;
                            end if;
                            insert into ZSDV_Datev_ExportLines (ZSDV_Datev_ExportLines_id,ZSDV_DATEV_EXPORT_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, dateacct,fact_acct_group,lineno, export_data )
                                    values(get_uuid(),p_exuid,v_client, p_OrgID,p_user,p_user,v_cur2.dateacct,v_cur2.fact_acct_group_id,v_line,v_satz);
                            v_rcount:=v_rcount+1;
                            v_korrektur:='';
                            v_belegfeld1:=''; v_kost2:='';v_kost1:='';v_belegfeld2:='';v_ziart3text:='';v_ziart4text:='';v_ziart5text:='';v_ziart6text:='';
                        end if; -- amt=0
                    end if;
                    END LOOP;
                    if v_check!=0 then
                        RAISE EXCEPTION '%','Datev-Export-Fehler: Soll und Haben ungleich: '||to_char(v_cur2.dateacct)||'   '||v_cur2.description||' Erg:'||to_char(v_check)||' Key:'||v_cur2.fact_acct_group_id;
                    end if;
            -- table ID
            end if;
            v_uid:='';
            v_adtaxINV:='';
            -- cur1
            END LOOP;
  RETURN 'SUCCESS: Datev-Export erfolgreich : '||to_char(v_rcount)||' Buchungssätze exportiert.';
END ; $BODY$  LANGUAGE 'plpgsql' 
VOLATILE  COST 100;



CREATE OR REPLACE FUNCTION zsfi_get_c_tax_id (
  p_ad_client_id varchar,
  p_datevkeyust varchar
)
RETURNS varchar AS
$body$
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C',  '2') AS zsfi_c_tax_id; -- gueltig -- SELECT * FROM c_tax WHERE c_tax_id = '4C0070761C0648238D5094682519FCE9'; -- 7%
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C',  '3') AS zsfi_c_tax_id; -- gueltig -- SELECT * FROM c_tax WHERE c_tax_id = '751E587B82E74FD18E8669D3E966D145'; -- 19%
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C',  '8') AS zsfi_c_tax_id; -- gueltig
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C',  '9') AS zsfi_c_tax_id; -- gueltig
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '18') AS zsfi_c_tax_id; -- gueltig -- 7%
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '19') AS zsfi_c_tax_id; -- gueltig -- 19% EU-steuerfrei
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '20') AS zsfi_c_tax_id; -- gueltig -- SELECT * FROM c_tax WHERE c_tax_id = '957C567BA6D9491499FAAC41AACB9723'; -- steuerfrei
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '22') AS zsfi_c_tax_id; -- gueltig -- SELECT * FROM c_tax WHERE c_tax_id = '957C567BA6D9491499FAAC41AACB9723'; -- MwSt 7%
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '23') AS zsfi_c_tax_id; -- gueltig -- SELECT * FROM c_tax WHERE c_tax_id = '957C567BA6D9491499FAAC41AACB9723'; -- MwSt 19%
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '28') AS zsfi_c_tax_id; -- gueltig
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '29') AS zsfi_c_tax_id; -- gueltig
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '34') AS zsfi_c_tax_id; -- gueltig, '957C567BA6D9491499FAAC41AACB9723' -- Aufhebung der Automatik=steuerfrei
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '40') AS zsfi_c_tax_id; -- gueltig, '957C567BA6D9491499FAAC41AACB9723' -- Aufhebung der Automatik=steuerfrei
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '47') AS zsfi_c_tax_id; -- gueltig, '957C567BA6D9491499FAAC41AACB9723' -- Aufhebung der Automatik=steuerfrei
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '42') AS zsfi_c_tax_id; -- gueltig, '957C567BA6D9491499FAAC41AACB9723' -- Aufhebung der Automatik=steuerfrei
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '69') AS zsfi_c_tax_id; -- gueltig
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '91') AS zsfi_c_tax_id; -- gueltig
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '94') AS zsfi_c_tax_id; -- gueltig
-- SELECT zsfi_get_c_tax_id('C726FEC915A54A0995C568555DA5BB3C', '99') AS zsfi_c_tax_id; -- NULL, ungueltig
-- SELECT * FROM c_tax -- WHERE c_tax_id = '957C567BA6D9491499FAAC41AACB9723' -- '0'
-- SELECT * FROM c_tax WHERE c_tax_id = '957C567BA6D9491499FAAC41AACB9723' -- '34' = rate=0, Steuerfrei Inland
-- SELECT * FROM c_tax WHERE c_tax_id = '9550FBA02FD54A34A2EBFBB09CE542D6' -- '94' = rate=19

DECLARE
  v_result               character varying;

  v_tax_c_tax_id         VARCHAR := '';
  v_tax_isactive         VARCHAR := ''; -- N , Y
  v_cln_ad_client_id     VARCHAR := '';
  v_cln_isactive         VARCHAR := ''; -- N , Y
  v_tax_datevkeyust      VARCHAR := '';
  v_datevkeyust          VARCHAR := '';
BEGIN
  v_datevkeyust := p_datevkeyust;
  IF (LENGTH(p_datevkeyust) = 1) THEN
      IF    (p_datevkeyust = '2') THEN
        v_datevkeyust := '8';             -- Umsatzsteuer 7%
      ELSEIF(p_datevkeyust = '3') THEN
        v_datevkeyust := '9';             -- Umsatzsteuer 19%
      END IF;
  ELSEIF (LENGTH(p_datevkeyust) = 2) THEN
    IF     (p_datevkeyust = '10') THEN    -- steuerfrei
      v_datevkeyust := '0';
    ELSEIF (p_datevkeyust = '11') THEN    -- steuerfrei
      v_datevkeyust := '0';
    ELSEIF (p_datevkeyust = '18') THEN
      v_datevkeyust := '8';
--  ELSEIF (p_datevkeyust = '19') THEN    -- deaktiviert, wird 1:1 durchgereicht, c_tax.rate=19
--    v_datevkeyust := '9';               -- deaktiviert 26.04.12

-- 2x: Generalumkehrbuchung
    ELSEIF (p_datevkeyust = '20') THEN    -- Generalumkehrbuchung, steuerfrei
      v_datevkeyust := '0';
  --ELSEIF (p_datevkeyust = '21') THEN    -- Generalumkehrbuchung, Umsatzsteuerfrei (mit Vorsteuerabzug)
  --  noch nicht aktiviert
    ELSEIF (p_datevkeyust = '22') THEN    -- Generalumkehrbuchung, Umsatzsteuer 7 %
      v_datevkeyust := '8';               -- 19.12.2012 added
    ELSEIF (p_datevkeyust = '23') THEN    -- Generalumkehrbuchung, Umsatzsteuer 19 %
      v_datevkeyust := '9';               -- 19.12.2012 added
  --ELSEIF (p_datevkeyust = '24') THEN    -- gesperrt
  --  noch nicht aktiviert
  --ELSEIF (p_datevkeyust = '25') THEN    -- Generalumkehrbuchung, Umsatzsteuer 16 %
  --  noch nicht aktiviert
  --ELSEIF (p_datevkeyust = '26') THEN    -- gesperrt
  --  noch nicht aktiviert
  --ELSEIF (p_datevkeyust = '27') THEN    -- Generalumkehrbuchung, Vorsteuer 16 %
  --  noch nicht aktiviert
    ELSEIF (p_datevkeyust = '28') THEN    -- Generalumkehrbuchung, Vorsteuer 7 %
      v_datevkeyust := '8';
    ELSEIF (p_datevkeyust = '29') THEN    -- Generalumkehrbuchung, Vorsteuer 19 %
      v_datevkeyust := '9';

-- 3x: Generalumkehr bei aufzuteilender Vorsteuer
    ELSEIF (p_datevkeyust = '30') THEN    -- Generalumkehr bei aufzuteilender Vorsteuer, gibt es 30 tatsaechlich ?
      v_datevkeyust := '0';
    ELSEIF (p_datevkeyust = '34') THEN    -- Generalumkehr bei aufzuteilender Vorsteuer
    --v_datevkeyust := '94';              -- deaktiviert wg 12.2012 6497 Wartungskosten SW
      v_datevkeyust := '0';               -- 27.04.12 ohne Steuer
    ELSEIF (p_datevkeyust = '38') THEN    -- Generalumkehr bei aufzuteilender Vorsteuer, Vorsteuer 7 %
      v_datevkeyust := '8';
    ELSEIF (p_datevkeyust = '39') THEN    -- Generalumkehr bei aufzuteilender Vorsteuer, Vorsteuer 19 %
      v_datevkeyust := '9';

-- 4x:
--  ELSEIF (p_datevkeyust = '40') THEN -- Aufhebung der Automatik / PRAP
    ELSEIF ( (SUBSTRING(p_datevkeyust, 1, 1) = '4') AND (LENGTH(p_datevkeyust) = 2) ) THEN -- Aufhebung der Automatik / PRAP / 47= nicht USt16%
      v_datevkeyust := '0';             -- keine Steuerbuchung

-- 6x:
    ELSEIF (p_datevkeyust = '69') THEN
      v_datevkeyust := '9';
-- 9x:
    ELSEIF (p_datevkeyust = '91') THEN
      v_datevkeyust := '8';
--  ELSEIF (p_datevkeyust = '94') THEN    -- deaktiviert, wird 1:1 durchgereicht, c_tax.rate=19
    END IF;
  END IF;

  
  
  if v_datevkeyust='8' then --MwSt 7%
    v_result := '4C0070761C0648238D5094682519FCE9';
  end if;
  if v_datevkeyust='9'  then --MwSt 19%
    v_result := '751E587B82E74FD18E8669D3E966D145';
  end if;
  if v_datevkeyust='19'  then --EU-Lieferungen 19%
    v_result := '956F94150FD84A07862675F3085004F2';
  end if;
  if v_datevkeyust='18'  then --EU-Lieferungen 7%
    -- TODO
    --v_result := '956F94150FD84A07862675F3085004F2';
  end if;
  if v_datevkeyust='94'  then --$13b, 19%
    v_result := '9550FBA02FD54A34A2EBFBB09CE542D6';
  end if;
  if v_datevkeyust='0' then --StFr. Inl.
    v_result := '957C567BA6D9491499FAAC41AACB9723';
  end if;
  if v_result is null then
    RAISE NOTICE '%', ' Datev-BU-Schluessel: ' || p_datevkeyust || ' nicht in Tabelle c_tax.datevkeyust hinterlegt';
  END IF;

  RETURN v_result;
END;
$body$
LANGUAGE 'plpgsql';


CREATE or replace FUNCTION zsdv_InsertDatevImport_01 (
  p_filename VARCHAR
)
  RETURNS VARCHAR
AS $body_$
-- SELECT zsdv_insertDatevImport_01('/tmp/DTVF_Buchungsstapel.csv') as plresult from dual;
DECLARE
  v_cur RECORD;
  i INTEGER := 0;
  v_anzLines INTEGER := 0;

  j INTEGER;
  v_header VARCHAR;
  v_headerLine VARCHAR;
  v_pos INTEGER := 0;
  v_sem INTEGER := 0;

  v_cmd VARCHAR := '';
  v_message VARCHAR := '';
BEGIN

  IF NOT EXISTS(
    SELECT relname FROM pg_class
    WHERE UPPER(relname) =  UPPER('I_PrimanotaImport') AND relkind = 'r') THEN
    RAISE NOTICE 'CREATE TABLE I_PrimanotaImport';
    -- DROP TABLE I_PrimanotaImport;
    CREATE TABLE I_PrimanotaImport (
      i_PrimanotaImport_id VARCHAR(32) DEFAULT get_uuid() NOT NULL,
      PrimanotaImportline VARCHAR(2500),
     CONSTRAINT i_PrimanotaImport_key PRIMARY KEY(i_PrimanotaImport_id)
    ) WITHOUT OIDS; -- SELECT * FROM I_PrimanotaImport
  ELSE
    TRUNCATE TABLE I_PrimanotaImport;
  END IF;

  IF NOT EXISTS(
    SELECT relname FROM pg_class
    WHERE UPPER(relname) =  UPPER('I_Primanota') AND relkind = 'r') THEN
    RAISE NOTICE 'CREATE TABLE I_Primanota';
    -- DROP TABLE I_Primanota;
    CREATE TABLE I_Primanota (
      i_01 VARCHAR(10),   -- "DTVF"
      i_02 VARCHAR(04),   -- 200
      i_03 VARCHAR(03),   -- 21
      i_04 VARCHAR(27),   -- "Buchungsstapel"
      i_05 VARCHAR(02),   -- 2
      i_06 VARCHAR(180),   -- 20111125103911150
      i_07 VARCHAR(27),   --
      i_08 VARCHAR(03),   -- "RE"
      i_09 VARCHAR(27),   -- "BenutzerName"
      i_10 VARCHAR(27),   -- ""
      i_11 VARCHAR(10),   -- 2720
      i_12 VARCHAR(10),   -- 30815
      i_13 VARCHAR(09),   -- 20111001
      i_14 VARCHAR(02),   -- 4            SKR04
      i_15 VARCHAR(09),   -- 20111031
      i_16 VARCHAR(09),   -- 20111031
      i_17 VARCHAR(255),  -- "BuchungsStapelName"
      i_18 VARCHAR(10),   -- "LO"
      i_19 VARCHAR(02),   -- 1
      i_20 VARCHAR(02),   -- 0
      i_21 VARCHAR(03),   -- 10
      i_22 VARCHAR(04),   -- "EUR"
      i_23 VARCHAR(02),   --
      i_24 VARCHAR(02),   -- 0
      i_25 VARCHAR(02),   --
      i_26 VARCHAR(10),   -- 268875
      created TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
      createdby VARCHAR(32) DEFAULT CURRENT_USER NOT NULL,
      importFilename VARCHAR
    ) WITHOUT OIDS; -- SELECT * FROM I_Primanota
  ELSE
    TRUNCATE TABLE I_Primanota;
  END IF;

  IF NOT EXISTS(
    SELECT relname FROM pg_class
    WHERE UPPER(relname) =  UPPER('I_PrimanotaLine') AND relkind = 'r') THEN
    RAISE NOTICE 'CREATE TABLE I_PrimanotaLine';
    -- DROP TABLE I_PrimanotaLine;
    CREATE TABLE I_PrimanotaLine (
      il_01 VARCHAR(014),-- 9000,00           -- Umsatz (ohne Soll/Haben-Kz)
      il_02 VARCHAR(001),--   "H"             -- Soll/Haben-Kennzeichen
      il_03 VARCHAR(010),--   ""              -- WKZ Umsatz
      il_04 VARCHAR(010),--                   -- Kurs
      il_05 VARCHAR(010),--                   -- Basis-Umsatz
      il_06 VARCHAR(010),--   ""              -- WKZ Basis-Umsatz
      il_07 VARCHAR(010),--   3790            -- Konto
      il_08 VARCHAR(010),--   6020            -- Gegenkonto (ohne BU-Schlüssel)
      il_09 VARCHAR(010),--   ""              -- BU-Schlüssel
      il_10 VARCHAR(010),--   3010            -- Belegdatum
      il_11 VARCHAR(027),--   "201110"        -- Belegfeld 1
      il_12 VARCHAR(010),--   ""              -- Belegfeld 2
      il_13 VARCHAR(010),--   9999999,99      -- Skonto-Betrag ( > 10.000.000,00)
      il_14 VARCHAR(255),--   "Gehalt"        -- Buchungstext
      il_15 VARCHAR(010),--                   -- Postensperre
      il_16 VARCHAR(010),--   ""              -- Diverse Adressnummer
      il_17 VARCHAR(027),--                   -- Geschäftspartnerbank
      il_18 VARCHAR(010),--                   -- Sachverhalt
      il_19 VARCHAR(010),--                   -- Zinssperre
      il_20 VARCHAR(255),--   ""              -- Beleglink
      il_21 VARCHAR(255),--   ""              -- Beleginfo - Art 1
      il_22 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 1
      il_23 VARCHAR(255),--   ""              -- Beleginfo - Art 2
      il_24 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 2
      il_25 VARCHAR(255),--   ""              -- Beleginfo - Art 3
      il_26 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 3
      il_27 VARCHAR(255),--   ""              -- Beleginfo - Art 4
      il_28 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 4
      il_29 VARCHAR(255),--   ""              -- Beleginfo - Art 5
      il_30 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 5
      il_31 VARCHAR(255),--   ""              -- Beleginfo - Art 6
      il_32 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 6
      il_33 VARCHAR(255),--   ""              -- Beleginfo - Art 7
      il_34 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 7
      il_35 VARCHAR(255),--   ""              -- Beleginfo - Art 8
      il_36 VARCHAR(255),--   ""              -- Beleginfo - Inhalt 8
      il_37 VARCHAR(018),--   "101"           -- KOST1 - Kostenstelle
      il_38 VARCHAR(018),--   "100"           -- KOST2 - Kostenstelle
      il_39 VARCHAR(255),--                   -- Kost-Menge
      il_40 VARCHAR(064),--   ""              -- EU-Land u. UStID
      il_41 VARCHAR(010),--                   -- EU-Steuersatz
      il_42 VARCHAR(010),--   ""              -- Abw. Versteuerungsart
      il_43 VARCHAR(255),--                   -- Sachverhalt L+L
      il_44 VARCHAR(255),--                   -- Funktionsergänzung L+L
      il_45 VARCHAR(010),--                   -- BU 49 Hauptfunktionstyp
      il_46 VARCHAR(010),--                   -- BU 49 Hauptfunktionsnummer
      il_47 VARCHAR(010),--                   -- BU 49 Funktionsergänzung
      il_48 VARCHAR(255),--   ""              -- Zusatzinformation - Art 1
      il_49 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 1
      il_50 VARCHAR(255),--   ""              -- Zusatzinformation - Art 2
      il_51 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 2
      il_52 VARCHAR(255),--   ""              -- Zusatzinformation - Art 3
      il_53 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 3
      il_54 VARCHAR(255),--   ""              -- Zusatzinformation - Art 4
      il_55 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 4
      il_56 VARCHAR(255),--   ""              -- Zusatzinformation - Art 5
      il_57 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 5
      il_58 VARCHAR(255),--   ""              -- Zusatzinformation - Art 6
      il_59 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 6
      il_60 VARCHAR(255),--   ""              -- Zusatzinformation - Art 7
      il_61 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 7
      il_62 VARCHAR(255),--   ""              -- Zusatzinformation - Art 8
      il_63 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 8
      il_64 VARCHAR(255),--   ""              -- Zusatzinformation - Art 9
      il_65 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 9
      il_66 VARCHAR(255),--   ""              -- Zusatzinformation - Art 10
      il_67 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 10
      il_68 VARCHAR(255),--   ""              -- Zusatzinformation - Art 11
      il_69 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 11
      il_70 VARCHAR(255),--   ""              -- Zusatzinformation - Art 12
      il_71 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 12
      il_72 VARCHAR(255),--   ""              -- Zusatzinformation - Art 13
      il_73 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 13
      il_74 VARCHAR(255),--   ""              -- Zusatzinformation - Art 14
      il_75 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 14
      il_76 VARCHAR(255),--   ""              -- Zusatzinformation - Art 15
      il_77 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 15
      il_78 VARCHAR(255),--   ""              -- Zusatzinformation - Art 16
      il_79 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 16
      il_80 VARCHAR(255),--   ""              -- Zusatzinformation - Art 17
      il_81 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 17
      il_82 VARCHAR(255),--   ""              -- Zusatzinformation - Art 18
      il_83 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 18
      il_84 VARCHAR(255),--   ""              -- Zusatzinformation - Art 19
      il_85 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 19
      il_86 VARCHAR(255),--   ""              -- Zusatzinformation - Art 20
      il_87 VARCHAR(255),--   ""              -- Zusatzinformation- Inhalt 20
      il_88 VARCHAR(020),--                   -- Stück
      il_89 VARCHAR(020),--                   -- Gewicht
      il_90 VARCHAR(027),--                   -- Zahlweise
      il_91 VARCHAR(010),--   ""              -- Forderungsart
      il_92 VARCHAR(004),--                   -- Veranlagungsjahr
      il_93 VARCHAR(018),--                   -- Zugeordnete Fälligkeit
      created TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
      createdby VARCHAR(32) DEFAULT CURRENT_USER NOT NULL
    ) WITHOUT OIDS; -- SELECT * FROM I_PrimanotaLine
  ELSE
    TRUNCATE TABLE I_PrimanotaLine;
  END IF;

-- Kopfsatz kopieren
  v_cmd := 'COPY I_PrimanotaImport (PrimanotaImportline) FROM ''' || p_filename ||''' ';
  RAISE NOTICE '%', v_cmd;
  EXECUTE(v_cmd);
  v_cmd := 'EXECUTE(v_cmd)';

  v_header := (SELECT PrimanotaImportline FROM i_PrimanotaImport LIMIT 1);
  v_headerLine := '';
  v_pos := 0;
  v_sem := 0;

  j := 1;
  WHILE (j <= LENGTH(v_header)) LOOP
    IF (SUBSTRING(v_header, j, 1) = ';') THEN
      v_sem := v_sem + 1;
    END IF;
    IF (v_sem < 26) THEN
      v_headerLine := v_headerLine || SUBSTRING(v_header, j , 1);
    ELSE
      EXIT; --exit loop, too many Semikolon
    END IF;
    j := (j + 1);
  END LOOP;

  UPDATE i_PrimanotaImport SET PrimanotaImportline = v_headerline WHERE SUBSTRING(PrimanotaImportline, 1, 6) LIKE '%DTVF%';

  COPY (SELECT PrimanotaImportline FROM i_PrimanotaImport WHERE SUBSTR(PrimanotaImportline, 1, 6) LIKE '%DTVF%') TO '/tmp/PrimanotaImport_Header.csv';
  COPY I_Primanota (
    i_01, i_02,  i_03, i_04, i_05, i_06, i_07, i_08, i_09, i_10, i_11, i_12, i_13,
    i_14,  i_15, i_16, i_17, i_18, i_19, i_20, i_21, i_22, i_23, i_24, i_25, i_26
  ) FROM '/tmp/PrimanotaImport_Header.csv' CSV DELIMITER AS ';' NULL AS 'NULL' QUOTE AS '"' ;
  v_cmd := 'COPY I_Primanota (i_01, i_02, .. , i_26) FROM ''' || '/tmp/PrimanotaImport_Header.csv' ||''' ';
  RAISE NOTICE '%', v_cmd;

  SELECT COUNT(*) INTO v_anzLines FROM I_Primanota;
  IF (v_anzLines > 0) THEN
    UPDATE I_Primanota SET importFilename = p_filename;
    v_message := v_anzLines || ' Datensätze importiert';
    RAISE NOTICE '%', v_message;
  ELSE
    v_message := '@ERROR=' || 'Kopfsatz-Information der Import-Datei konnte nicht ermittelt werden (Zeile 1: DTVF ff.).';
    RAISE NOTICE '%', v_message;
    RETURN v_message;
  END IF;

-- Buchungssaetze kopieren
--COPY (SELECT PrimanotaImportline FROM i_PrimanotaImport OFFSET 2) TO '/tmp/PrimanotaImport_Data.csv';
  COPY (
    SELECT PrimanotaImportline FROM i_PrimanotaImport
    WHERE SUBSTR(PrimanotaImportline, 1, 1) IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
       ) TO '/tmp/PrimanotaImport_Data.csv';
  COPY I_PrimanotaLine (
    il_01, il_02, il_03, il_04, il_05, il_06, il_07, il_08, il_09, il_10,
    il_11, il_12, il_13, il_14, il_15, il_16, il_17, il_18, il_19, il_20,
    il_21, il_22, il_23, il_24, il_25, il_26, il_27, il_28, il_29, il_30,
    il_31, il_32, il_33, il_34, il_35, il_36, il_37, il_38, il_39, il_40,
    il_41, il_42, il_43, il_44, il_45, il_46, il_47, il_48, il_49, il_50,
    il_51, il_52, il_53, il_54, il_55, il_56, il_57, il_58, il_59, il_60,
    il_61, il_62, il_63, il_64, il_65, il_66, il_67, il_68, il_69, il_70,
    il_71, il_72, il_73, il_74, il_75, il_76, il_77, il_78, il_79, il_80,
    il_81, il_82, il_83, il_84, il_85, il_86, il_87, il_88, il_89, il_90,
    il_91, il_92, il_93)
  FROM '/tmp/PrimanotaImport_Data.csv' CSV DELIMITER AS ';' QUOTE AS '"' ;          --  NULL AS 'NULL'
  v_cmd := 'COPY I_PrimanotaLine (il_01, il_02, .. , il_93) FROM ''' || '/tmp/PrimanotaImport_Data.csv' ||''' ';
  RAISE NOTICE '%', v_cmd;

  SELECT COUNT(*) INTO v_anzLines FROM I_PrimanotaLine;
  v_message := v_anzLines || ' Datensätze in Tabelle I_PrimanotaLine importiert';
  RAISE NOTICE '%', v_message;

  v_message := 'SUCCESS - '  || v_anzLines || ' Datensätze importiert';
  RAISE NOTICE '%', v_message;

  RETURN v_message;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;
    RAISE NOTICE '%', v_message;
    RETURN v_message;
END;
$body_$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsdv_insertDatevImport_02 (p_ad_org_id VARCHAR)
RETURNS
  VARCHAR  -- 'SUCCESS'
AS $body_$
-- SELECT zsdv_insertDatevImport_02('AE3637495E9E4EBFA7E766FE9B97893A') AS message;
-- SELECT * from zsfi_manualacct
-- UPDATE c_elementvalue SET value = LPAD(value, 4, '0000') WHERE LENGTH(value) < 4
DECLARE
  v_messArray     VARCHAR[];      -- dyn. erweiterbares Array
  v_assetArray    VARCHAR[];      -- dyn. erweiterbares Array
  v_anzError      INTEGER := 0;   -- Überschrift für Fehlermeldung = v_messArray[0]

  v_ad_client_id  VARCHAR := '';  -- 'C726FEC915A54A0995C568555DA5BB3C';

  v_anz           INTEGER := 0;
  v_ksst_value    VARCHAR;

  i INTEGER := 0;
  j INTEGER := 0;
  k INTEGER := 0; -- count a_asset found, imported
  l INTEGER := 0; -- count a_asset found, not imported
  m INTEGER := 0;
  v_cmd              VARCHAR := '';
  v_message          VARCHAR := '';
  v_accounttype      VARCHAR;
  v_name             VARCHAR;
  v_isDocControlled  VARCHAR;
  v_c_element_id     VARCHAR;
  v_el_element_name  VARCHAR;
  v_el_c_element_id  VARCHAR;
  v_konto            VARCHAR;
BEGIN
  v_message := 'Folgende Fehler bei der Verarbeitung gefunden:';
  v_messArray[0] := v_message;
  v_assetArray[0] := 'Liste unbekannte Kostenstellen:';

  SELECT ad_client_id
  INTO v_ad_client_id
  FROM ad_org org WHERE org.ad_org_id = p_ad_org_id; -- 'AE3637495E9E4EBFA7E766FE9B97893A';
  IF isempty(v_ad_client_id) THEN
    v_anzError := v_anzError + 1;
    v_message := '@ERROR=ad_org.ad_client_id nicht gefunden ';
    RETURN v_message;
  END IF;

  v_c_element_id := (SELECT zsfi_get_c_element_id(p_ad_org_id)); -- D871D9715A904125974B545FC0FF0681 = SKR04
  IF isempty(v_c_element_id) THEN
    v_anzError := v_anzError + 1;
    v_message := '@ERROR=Sachkontenrahmen nicht gefunden zu ad_org_id=' || p_ad_org_id;
    RETURN v_message;
  END IF;

  SELECT el.c_element_id, el.name INTO v_el_c_element_id, v_el_element_name FROM c_element el WHERE el.c_element_id = v_c_element_id;
  RAISE NOTICE 'Sachkontorahmen: %=%', v_el_c_element_id, v_el_element_name;
  IF (v_c_element_id not in ('D871D9715A904125974B545FC0FF0681','C76385D3874B4775B28CEC5ECBCE1E5B' )) THEN
    v_anzError := v_anzError + 1;
    v_message := '@ERROR=Es kann bislang nur Sachkontenrahmen SKR03 / SKR04 verarbeitet werden=' || p_ad_org_id;
    RETURN v_message;
  END IF;

  DECLARE
    CUR_Lines RECORD;
    v_NextNo VARCHAR(32);
  BEGIN
    FOR CUR_Lines IN (
      SELECT
        il_07,  -- c_elementvalue.c_elementvalue_id: Konto
        il_08,  -- c_elementvalue.c_elementvalue_id: Gegenkonto
        il_37   -- a_asset. Kostenstelle
    FROM I_PrimanotaLine
      ) -- SELECT * FROM I_PrimanotaLine l WHERE (LENGTH(il_07) >= 5) OR (LENGTH(il_08) >= '5')
    LOOP
      i := i + 1;

     FOR m IN 1..2 LOOP
       IF (m = 1) THEN
        -- SachKonto ggfls korrigieren
         IF NOT isempty(CUR_Lines.il_07) THEN
           IF (LENGTH(CUR_Lines.il_07) <= 3) THEN
             v_konto := LPAD(replace(CUR_Lines.il_07,' ',''), 4, '0000'); -- SKTO(4)
           ELSE
             v_konto := replace(CUR_Lines.il_07,' ',''); -- SKTO(4) / PKTO(P+5)
           END IF;
         END IF;
       ELSE
         IF NOT isempty(CUR_Lines.il_08) THEN
           IF (LENGTH(CUR_Lines.il_08) <= 3) THEN
             v_konto := LPAD(CUR_Lines.il_08, 4, '0000'); -- SKTO(4)
           ELSE
             v_konto := CUR_Lines.il_08; -- SKTO(4) / PKTO(P+5)
           END IF;
         END IF;
       END IF;

      IF NOT isempty(v_konto) AND LENGTH(v_konto) >= 4 THEN
    -- A=Asset/Aktiva/Anlagen, E=Expense/Kosten (GuV), L=Liability/Passiva/Schulden, O=Owners Equity/Eigenkapital, R=Revenue/Ertrag (GuV)
        v_name := 'NN-Datev-Import';
        v_isDocControlled := 'N';
        IF (     (LENGTH(v_konto) = 5) AND (SUBSTRING(v_konto, 1, 1) = '1') ) THEN -- Debitor 1xxxx
          v_accounttype := 'P';
          v_konto := 'P' || v_konto;
          v_name := 'NN-Debitor';
        ELSEIF ( (LENGTH(v_konto) = 5) AND (SUBSTRING(v_konto, 1, 1) = '7') ) THEN -- Kreditor 7xxxxx
          v_accounttype := 'P';
          v_konto := 'P' || v_konto;
          v_name := 'NN-Kreditor';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '0') ) THEN
          v_accounttype := 'A'; -- Asset (AV)
          v_name := 'NN-AV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '1') ) THEN
          v_accounttype := 'A'; -- Asset (UV)
          v_name := 'NN-UV';
--          ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '2') ) THEN
--            v_accounttype := 'A'; -- Asset (UV)
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '3') ) THEN
          v_accounttype := 'L'; -- Liability (FK)
          v_name := 'NN-FK';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '4') ) THEN
          v_accounttype := 'R'; -- Revenue (Ertrag)
          v_name := 'NN-GuV';
          IF     (SUBSTRING(v_konto, 1, 3) = '430') THEN     -- 19%
            v_isDocControlled := 'Y';
          ELSEIF (SUBSTRING(v_konto, 1, 3) = '440') THEN     -- 19%
            v_isDocControlled := 'Y';
          ELSEIF (SUBSTRING(v_konto, 1, 3) = '441') THEN     -- 19%
            v_isDocControlled := 'Y';
          END IF;
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '5') ) THEN
          v_accounttype := 'E'; -- Expense (Aufwand/Kosten)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '6') ) THEN
          v_accounttype := 'E'; -- Expense (Aufwand/Kosten)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 2) = '71') ) THEN
          v_accounttype := 'R'; -- Revenue (Ertrag)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 2) = '72') ) THEN
          v_accounttype := 'E'; -- Expense (Aufwand/Kosten)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 2) = '73') ) THEN
          v_accounttype := 'E'; -- Expense (Aufwand/Kosten)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 2) = '74') ) THEN
          v_accounttype := 'R'; -- Revenue (Ertrag)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 2) = '75') ) THEN
          v_accounttype := 'E'; -- Expense (Aufwand/Kosten)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 2) = '76') ) THEN
          v_accounttype := 'E'; -- Expense (Aufwand/Kosten)
          v_name := 'NN-GuV';
        ELSEIF ( (LENGTH(v_konto) = 4) AND (SUBSTRING(v_konto, 1, 1) = '8') ) THEN
          v_accounttype := 'E'; -- Expense (Aufwand/Kosten)
          v_name := 'NN-GuV';
        ELSEIF ( v_konto = '9000') THEN
          v_accounttype := 'A'; -- Saldovortag Skto
        ELSEIF ( v_konto = '9008') THEN
          v_accounttype := 'M'; -- Saldovortag Debitor
        ELSEIF ( v_konto = '9009') THEN
          v_accounttype := 'M'; -- Saldovortag Kreditor
        END IF;
        -- Kontenerstellung nur bei SKR04 implementiert.
        IF isempty(zsfi_get_c_elementvalue_id(p_ad_org_id, v_konto)) and v_c_element_id = 'D871D9715A904125974B545FC0FF0681' THEN  -- SKTO(4) + PKTO(P+5)
          INSERT INTO c_elementvalue (
            c_elementvalue_id, ad_client_id, ad_org_id, createdby, updatedby,  value,   name,    description, accounttype, accountsign,   c_element_id, c_currency_id, isDocControlled)
          VALUES ( get_uuid(), v_ad_client_id, p_ad_org_id,   '0',      '0', v_konto, v_name, 'Datev-Import', v_accounttype,         'N', v_c_element_id,      '102',  v_isDocControlled);
          RAISE NOTICE '%', 'Konto hinzugefügt: ' || v_konto;
          j := j + 1;
        END IF;
      END IF;

     END LOOP;


    END LOOP;

  END;

  -- wenn Fehler gefunden, Exception provozieren für Ausgabe Fehlermeldungen
  IF (v_anzError > 0 ) THEN
    RAISE EXCEPTION '%', 'Fehler Import'; -- > Exception-Handling
  ELSE
    v_message := 'SUCCESS';
    IF (j > 0) THEN
      v_message := v_message  || '</br>' || j || ' Konten bei Datev-Import aus Tabelle ''I_PrimanotaLine'' in Tabelle ''c_elementvalue'' eingefuegt';
    ELSE
      v_message := v_message  || '</br>' || ' Keine neuen Konten bei Datev-Import gefunden';
    END IF;
    -- Kostenstellen
    IF (k > 0) THEN
      v_message := v_message  || '</br>' || k || ' KostenStellen bei Datev-Import aus Tabelle ''I_PrimanotaLine'' in Tabelle ''a_asset'' eingefuegt';
    ELSEIF (l > 0) THEN
      v_message := v_message  || '</br>' || ' Bislang unbekannte Kostenstellen bei Datev-Import gefunden, keine automatische Übernahme.';
   -- Fehlermeldungen ausgeben
      j := 0; -- v_assetArray[0] = 'unbekannte Kostenstellen';
      LOOP
        IF (v_assetArray[j] IS NOT NULL) THEN
          v_message := v_message || E'\r\n' || v_assetArray[j];
        ELSE
          EXIT;
        END IF;
        j := j + 1;
      END LOOP;
    ELSE
      v_message := v_message  || '</br>' || 'Keine neuen KostenStellen bei Datev-Import gefunden';
    END IF;
    RAISE NOTICE '%', v_message;
    RETURN v_message;
  END IF;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;

   -- Fehlermeldungen ausgeben
    j := 0;
    LOOP
      IF (v_messArray[j] IS NOT NULL) THEN
        -- RAISE NOTICE '%', v_messArray[j];
        v_message := v_message || '</br>' || v_messArray[j];
      ELSE
        EXIT;
      END IF;
      j := j + 1;
    END LOOP;
    RAISE NOTICE '%', replace(v_message,'</br>',E'\r\n');
    RETURN v_message;
END;
$body_$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION zsdv_insertdatevimport_03 (
  p_ad_org_id varchar
)
RETURNS varchar AS
$body$
-- SELECT zsdv_insertDatevImport_03('AE3637495E9E4EBFA7E766FE9B97893A') AS message;
DECLARE
  v_datevType      INTEGER := 0;
  v_calcType       INTEGER := 0;
  v_importFilename VARCHAR := '';
  v_messArray     VARCHAR[];      -- dyn. erweiterbares Array
  v_anzError      INTEGER := 0;   -- Überschrift für Fehlermeldung = v_messArray[0]

  v_ad_client_id  VARCHAR := '';  -- 'C726FEC915A54A0995C568555DA5BB3C';
  v_isActive      VARCHAR := 'Y';
  v_created       TIMESTAMP WITHOUT TIME ZONE := CURRENT_TIMESTAMP;
  v_createdBy     VARCHAR := '0';
  v_16            DATE;           -- Buchungsdatum acctdate
  v_17            VARCHAR := '';  -- Description DBB
  v_22            VARCHAR := '';  -- Währung EUR
  v_asset  varchar;
  v_prj    varchar;
  v_prt    varchar;

  v_acctcr_id     VARCHAR;        -- GUID für c_elementvalue.c_elementvalue_id
  v_acctdr_id     VARCHAR;        -- GUID für c_elementvalue.c_elementvalue_id
  h_acctcr_id     VARCHAR;
  v_description   VARCHAR;
  v_Beleginfo1    VARCHAR;
  v_c_tax_id      VARCHAR;        -- Steuerschlussel aus c_tax -- SELECT * FROM c_tax
  v_documentno    VARCHAR;        -- NULL nicht erlaubt
  v_accounttype_07 VARCHAR;
  v_accounttype_08 VARCHAR;
  v_accountValue_07 VARCHAR;
  v_accountValue_08 VARCHAR;

  v_zsfi_manualacct_id VARCHAR := get_uuid();
  v_amt           NUMERIC := 0;
  v_line          INTEGER := 10;
  v_il_09         VARCHAR;        -- il_09, Buchungsschluessel
  v_SkontoAmt     NUMERIC;        -- il_13, Skonto-Betrag
  v_mitSktonto    BOOLEAN;
  v_isdr2cr       VARCHAR;        -- zsfi_macctline.isdr2cr
  v_isGross       VARCHAR;        -- Brutto, enthaelt Steuer
  v_isGUmkB       BOOLEAN;

  i INTEGER := 0;
  j INTEGER := 0;
  m INTEGER := 0;
  v_cmd VARCHAR := '';
  v_message  VARCHAR := '';
  v_isDocControlled     VARCHAR;
  v_isDocControlled_07  VARCHAR;
  v_isDocControlled_08  VARCHAR;
  v_link                VARCHAR;
  v_kost1conf       varchar:=''; -- Konfig
  v_kost2conf       varchar:=''; -- Konfig
  v_acctlen         integer;
BEGIN
  v_message := 'Folgende Fehler bei der Verarbeitung gefunden:';
  v_messArray[0] := v_message;
  select trunc(to_number(VALUE)) into  v_acctlen from ad_preference where attribute='DATEVACCTLEN';
  select o.ad_client_id,a.datevcost1,a.datevcost2 into v_ad_client_id,v_kost1conf,v_kost2conf from ad_org o,ad_org_acctschema x,c_acctschema a where o.ad_org_id=x.ad_org_id and x.c_acctschema_id=a.c_acctschema_id and o.ad_org_id=p_ad_org_id;

  IF ( (v_ad_client_id IS NULL) OR (LENGTH(v_ad_client_id) = 0) ) THEN
    v_anzError := v_anzError + 1;
    v_message := '@ERROR=ad_org.ad_client_id nicht gefunden ';
    RETURN v_message;
  END IF;
  IF (v_anzError = 0) THEN
    SELECT AD_Sequence_Doc('DocumentNo_zsfi_manualacct', p_ad_org_id, 'Y') INTO v_documentno;
    SELECT
      to_date(SUBSTRING(i_16, 7, 2) ||'.'|| SUBSTRING(i_16, 5, 2) || '.' || SUBSTRING(i_16, 1, 4)), -- Buchungsdatum
      i_17, -- Beschreibung
      i_22, -- Waehrung
      importFilename
    INTO
      v_16,  -- zsfi_manualacct.acctdate 'YYYYMMDDHHMMSS' -> YYYY-MM-DD
      v_17,  -- description
      v_22,  --
      v_importFilename
    FROM I_Primanota LIMIT 1; -- SELECT * FROM I_Primanota LIMIT 1;
    v_messArray[0] := v_messArray[0] || '</br>' || v_importFilename;

    v_17 := TRIM(SUBSTRING(COALESCE(v_17, 'NO description by DBB') || ' / ' || v_importFilename, 1, 255));

    INSERT INTO zsfi_manualacct
    (
      zsfi_manualacct_id, ad_client_id, ad_org_id, isactive,
      created, createdby, updated, updatedby,
      description, acctdate,
      glstatus, processing, post, cancel, unpost, documentno,
      c_project_id, c_projectphase_id, c_projecttask_id, a_asset_id
    )
    VALUES (
      v_zsfi_manualacct_id, v_ad_client_id, p_ad_org_id, v_isactive,
      v_created, v_createdby, v_created, v_createdby,
      COALESCE(v_17, 'NO description by DBB'), -- description DBB, NOT NULL
      v_16, -- acctdate
      'OP', -- glstatus, OP=nicht verbucht / open booking
      'N',  -- processing,
      'N',  -- post
      'N',  -- cancel
      'N',  -- unpost
      v_documentno, -- documentno,
      NULL,         -- c_project_id,
      NULL,         -- c_projectphase_id,
      NULL,         -- c_projecttask_id,
      NULL          -- a_asset_id
    );
    -- SELECT * FROM I_PrimanotaLine l;
  END IF;
  RAISE NOTICE 'Buchungsstapel zsfi_manualacct.v_zsfi_manualacct_id = %', v_zsfi_manualacct_id;
  DECLARE
    CUR_Lines RECORD;
    v_NextNo VARCHAR(32);
  BEGIN 
    FOR CUR_Lines IN (
      SELECT
        il_01,  --  A: v_amt
        il_02,  --  B: S/H
        il_03,  --  C: WKZ/ ISO-Währung
        il_04,  --  D: Kurs fuer Fremdwaehrungsbetrag aus il_01
        il_07,  --  G: c_elementvalue.c_elementvalue_id: Konto
        il_08,  --  H: c_elementvalue.c_elementvalue_id: Gegenkonto
        il_09,  --  I: Buchungsschluessel
        il_13,  --  M: v_SkontoAmt
        il_10,  -- acctdate
        il_14,  --  N: v_description, 'Datev.Buchungstext'
        il_24,  --  X: v_Beleginfo1, 'Beleginfo Info 1'
        il_37,   -- Projekt (value) (KOST1)
        il_38,   -- Kostenstelle (KOST2)
        il_11,    -- Rechnungsnummer (belegfeld1)
        il_59,  -- Projektaufgabe (Name)
        
        to_date(SUBSTRING(lpad(il_10,4,'0'), 1, 2) || '.' || SUBSTRING(lpad(il_10,4,'0'), 3, 2)||'.'|| to_char(v_16, 'YYYY'),'DD.MM.YYYY' ) as acctdate -- Buchungsdatum
    FROM I_PrimanotaLine l
      ) -- SELECT * FROM I_PrimanotaLine l
    LOOP
      i := i + 1;
      IF isempty(CUR_Lines.il_04) THEN -- ohne WechselKurs=EUR
        v_amt  := to_number(REPLACE(CUR_Lines.il_01, ',', '.') );  --REPLACE(il_01,',','.')
      ELSE
        v_amt  := ROUND((to_number(REPLACE(CUR_Lines.il_01, ',', '.')) / to_number(REPLACE(CUR_Lines.il_04, ',', '.'))), 2); -- Fremdwaehrungsbetrag umrechnen
      END IF;
      v_description := CUR_Lines.il_14; -- NOT NULL
      v_Beleginfo1 := TRIM(REPLACE(COALESCE(CUR_Lines.il_24, ''), '  ', ' ')); -- NOT NULL, Leerzeichen komprimieren
      v_isdr2cr := '?';       -- Buchungsschluessel lt. il_09
      v_isGross := 'N';       -- ist Bruttobetrag lt. il_09
      v_isGUmkB := FALSE;     -- ist Generalumkehrbuchung
      v_c_tax_id := NULL;
      v_accountValue_07 := NULL;
      v_accountValue_08 := NULL;
      v_accounttype_07 := NULL;
      v_accounttype_08 := NULL;
      v_isDocControlled := NULL;
      v_isDocControlled_07 := NULL;
      v_isDocControlled_08 := NULL;
      v_SkontoAmt := COALESCE(to_number(REPLACE(CUR_Lines.il_13, ',', '.') ), 0);
      v_mitSktonto := (v_SkontoAmt > 0);

      IF (isempty(CUR_Lines.il_01)) THEN
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_01: Umsatz (Buchungsbetrag) nicht angegeben - Eintrag erforderlich';
        v_anzError := v_anzError + 1;
        v_messArray[v_anzError] := v_message;
      END IF;

      IF (isempty(CUR_Lines.il_02)) THEN
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_02: Soll/Haben-Kennzeichen nicht angegeben - Eintrag erforderlich';
        v_anzError := v_anzError + 1;
        v_messArray[v_anzError] := v_message;
      END IF;

      IF (isempty(CUR_Lines.il_07)) THEN
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_07: Konto nicht angegeben - Eintrag erforderlich';
        v_anzError := v_anzError + 1;
        v_messArray[v_anzError] := v_message;
      ELSE
        IF (LENGTH(CUR_Lines.il_07) < v_acctlen) THEN -- fehlende fuehrende '0' bei Sachkonto ergaenzen
          v_accountValue_07 := LPAD(replace(CUR_Lines.il_07,' ',''), v_acctlen, '0');                      -- SKTO(3->4): '675' >> '0675'
          v_acctcr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_07);
      --  ELSEIF( (LENGTH(CUR_Lines.il_07) = 5) AND (SUBSTRING(CUR_Lines.il_07, 1, 1) = '1') ) THEN
      --    v_accountValue_07 := 'P' || CUR_Lines.il_07;
      --    v_acctcr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_07);  -- Debitor
      --  ELSEIF( (LENGTH(CUR_Lines.il_07) = 5) AND (SUBSTRING(CUR_Lines.il_07, 1, 1) = '7') ) THEN
      --    v_accountValue_07 :=  'P' || CUR_Lines.il_07;
      --    v_acctcr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_07);  -- Kreditor
        ELSE
          v_accountValue_07 := replace(CUR_Lines.il_07,' ','');
          v_acctcr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_07);  -- SKTO(4)
        END IF;
      END IF;

      IF (isempty(CUR_Lines.il_08)) THEN
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_08: Gegenkonto nicht angegeben - Eintrag erforderlich';
        v_anzError := v_anzError + 1;
        v_messArray[v_anzError] := v_message;
      ELSE
        IF (LENGTH(CUR_Lines.il_08) < v_acctlen) THEN -- fehlende fuehrende '0' bei Sachkonto ergaenzen
          v_accountValue_08 := LPAD(replace(CUR_Lines.il_08,' ',''), v_acctlen, '0');                     -- SKTO(3->4): '675' >> '0675'
          v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_08);
        --ELSEIF( (LENGTH(CUR_Lines.il_08) = 5) AND (SUBSTRING(CUR_Lines.il_08, 1, 1) = '1') ) THEN
        --  v_accountValue_08 := 'P' || CUR_Lines.il_08;
        --  v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_08); -- Debitor
        --  if (v_acctdr_id) is null then
        --     v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, CUR_Lines.il_08); -- Debitor
        --  end if;
        --ELSEIF( (LENGTH(CUR_Lines.il_08) = 5) AND (SUBSTRING(CUR_Lines.il_08, 1, 1) = '7') ) THEN
        --  v_accountValue_08 := 'P' || CUR_Lines.il_08;
        --  v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_08); -- Kreditor
        --  if (v_acctdr_id) is null then
        --     v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, CUR_Lines.il_08); -- Kreditor
        --  end if;
        ELSE
          v_accountValue_08 := replace(CUR_Lines.il_08,' ','');
          v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_08); -- SKTO(4)
        END IF;
      END IF;
      -- RAISE NOTICE 'v_isGross=%, v_SkontoAmt=%, v_accountValue_07=%, v_accountValue_08=%', v_isGross, v_SkontoAmt, v_accountValue_07, v_accountValue_08;

      IF (isempty(CUR_Lines.il_14)) THEN  -- v_description = Datev.Buchungstext
--      v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_14: Buchungstext nicht angegeben - Eintrag erforderlich';
--      v_anzError := v_anzError + 1;
--      v_messArray[v_anzError] := v_message;
        v_description := ''; -- nicht angeliefert, Leerstring mind. erforderlich
      END IF;

      IF (v_acctcr_id IS NULL) THEN
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_07: Konto nicht im Sachkontenstamm angelegt: ' || CUR_Lines.il_07;
        v_anzError := v_anzError + 1;
        v_messArray[v_anzError] := v_message;
      END IF;

      IF (v_acctdr_id IS NULL) THEN
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_08: Konto nicht im Sachkontenstamm angelegt: ' || CUR_Lines.il_08;
        v_anzError := v_anzError + 1;
        v_messArray[v_anzError] := v_message;
      END IF;

      IF (NOT isempty(CUR_Lines.il_02)) THEN
        IF (CUR_Lines.il_02 = 'S') THEN
         v_isdr2cr := 'N';
        ELSEIF(CUR_Lines.il_02 = 'H') THEN
          v_isdr2cr := 'Y';
        ELSE
          v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_02: Fehlerhaftes S/H-Kennzeichen: ' || CUR_Lines.il_02;
          v_anzError := v_anzError + 1;
          v_messArray[v_anzError] := v_message;
        END IF;
      ELSE -- isempty(CUR_Lines.il_02)
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_02: Kein S/H-Kennzeichen in Spalte il_02 angegeben.';
        v_anzError := v_anzError + 1;
        v_messArray[v_anzError] := v_message;
      END IF;

      IF (NOT isempty(CUR_Lines.il_09)) THEN               -- Buchungsschluessel

      -- Buchungsschluessel il_09 angegeben:
      -- ( 8, 9, 28, 29, 94, ...) diese stehen für einen Vorsteuerschlüssel => '8'=7% // '9'=19%
      -- alle Zahlen mit einer 2 davor (20, 28, 29) bedeuten Generalumkehrbuchung
      -- 94 = Steuerschuld Empfänger nach §13
        v_isGross := '?';    -- Brutto, enthaelt Steuer: unzulaessiger Wert
        v_il_09 := TRIM(CUR_Lines.il_09);  -- '8', '9', '20', '28', '29', '94'
        v_c_tax_id := (SELECT zsfi_get_c_tax_id(v_ad_client_id , v_il_09));  -- c_tax, ad_client
        IF (v_c_tax_id IS NULL) THEN
          v_anzError := v_anzError + 1;
          v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_09: Buchungsschluessel nicht verarbeitet: ' || CUR_Lines.il_09;
          v_messArray[v_anzError] := v_message;
        END IF;
      -- gelieferte BU-Schluessel
        IF     (v_il_09 = '1') THEN  -- Umsatzsteuerfrei (mit Vorsteuerabzug)
          v_isGross := 'N';          -- dummy-Anweisung wg. Vollstaendigkeit
        ELSEIF (v_il_09 = '2') THEN  -- Umsatzsteuer 7%
          v_isGross := 'Y'; -- Brutto, enthaelt Steuer
        ELSEIF (v_il_09 = '3') THEN  -- Umsatzsteuer 19%
          v_isGross := 'Y'; -- Brutto, enthaelt Steuer
        ELSEIF (v_il_09 = '8') THEN  -- Vorsteuer 7%
          v_isGross := 'Y'; -- Brutto, enthaelt Steuer
        ELSEIF (v_il_09 = '9') THEN  -- Vorsteuer 19%
          v_isGross := 'Y'; -- Brutto, enthaelt Steuer
        ELSEIF ( (SUBSTRING(v_il_09, 1, 1) = '1')  AND (LENGTH(v_il_09) = 2) ) THEN  -- 1x = '10'..'19' EU-Tatbestand
          IF ( (v_il_09 = '10') OR (v_il_09 = '11') )  THEN
            v_isGross := 'N';     -- steuerfrei
          ELSE
           v_isGross := 'Y';      -- Brutto, enthaelt Steuer: '17'=16%, '18'=7%, '19'=19%
          END IF;
        ELSEIF (SUBSTRING(v_il_09, 1, 1) = '2' AND (LENGTH(v_il_09) = 2) )        -- 2x Generalumkehrbuchung: 20..29
        OR     (SUBSTRING(v_il_09, 1, 1) = '3' AND (LENGTH(v_il_09) = 2) ) THEN   -- 3x Generalumkehr bei aufzuteilender Vorsteuer
          v_amt := (v_amt * -1);  -- Generalumkehrbuchung
          v_isGUmkB := TRUE;
          IF ( (v_il_09 = '20') OR (v_il_09 = '30') OR (v_il_09 = '34') ) THEN    -- '34'=Generalumkehr, ohne Automatik=steuerfrei
            v_isGross := 'N';     -- steuerfrei
          ELSE
           v_isGross := 'Y';      -- Brutto, enthaelt Steuer: '28'=7%, '29'=19%
          END IF;
    --  ELSEIF ( (v_il_09) = '46') ) THEN  -- 46 noch nicht abweichend von 4x implementiert
        ELSEIF ( (SUBSTRING(v_il_09, 1, 1) = '4') AND (LENGTH(v_il_09) = 2) ) THEN  -- 4x
          v_isGross := 'N';       -- steuerfrei, Aufhebung der Automatik
        ELSEIF ( (SUBSTRING(v_il_09, 1, 1) = '6') AND (LENGTH(v_il_09) = 2) ) THEN  -- 6x Generalumkehrbuchung
          v_amt := (v_amt * -1);  -- Generalumkehrbuchung
          v_isGUmkB := TRUE;
          IF ( (v_il_09 = '60') OR (v_il_09 = '61') )  THEN
            v_isGross := 'N';     -- steuerfrei
          ELSE
           v_isGross := 'Y';      -- Brutto, enthaelt Steuer: '67'=16% '68'=7%, '69'=19%
          END IF;
        ELSEIF ( (v_il_09 = '91') OR (v_il_09 = '94') ) THEN                        -- 9x Steuer bei Leistungsempfaenger : mit Vorsteuer 7%/19%, mit 7%/19% Umsatzsteuer
           v_isGross := 'Y';      -- Brutto, enthaelt Steuer: '91'=7%, '94'=19%
    --  ELSEIF ( (v_il_09) = '92') OR (v_il_09) = '95') ) THEN                      -- 9x Steuer bei Leistungsempfaenger : ohne Vorsteuer, mit 7%/19% Umsatzsteuer
        END IF;

        -- BU-Schluessel geliefert, aber ungueltig
        IF ( (v_isGross = '?') OR (v_c_tax_id IS NULL) ) THEN -- unzulaessiger Wert, bislang nicht gesetzt
          v_anzError := v_anzError + 1;
          v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_09: Buchungsschluessel unbekannt: ' || CUR_Lines.il_09;
          v_messArray[v_anzError] := v_message;
          CONTINUE;
        END IF;

      ELSE  -- NOT isempty() / kein Buchungsschluessel angegegeben

       -- kein BU-Schlussel geliefert - Steuer nicht angegeben - c_tax.datevkeyust='0' für 'Steuerfrei Inland' ermitteln
       IF (isempty(v_c_tax_id)) THEN
        v_c_tax_id := zsfi_get_c_tax_id(v_ad_client_id, '0');  -- c_tax, ad_client
        IF (v_c_tax_id IS NULL) THEN
          v_anzError := v_anzError + 1;
          v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_09: Buchungsschluessel ''0'' in Steuerstamm c_tax nicht hinterlegt';
          v_messArray[v_anzError] := v_message;
          CONTINUE;
        END IF;
       END IF;
      END IF;

     -- pruefen, ob Automatikkonto - dann Steuerschluessel setzen, egal, was bislang ermittelt wurde
      -- Pruefung Bilanz/ GUVKTO - keine Pruefung bei Personenkonten: 'Pnnnnn, LENGTH >= 5
      IF(SUBSTR(v_accountValue_07, 1, 1) <> 'P') THEN
        v_isDocControlled_07 := (SELECT zsfi_get_c_elementvalue(p_ad_org_id, v_accountValue_07, 'isDocControlled'));
      END IF;
      IF(SUBSTR(v_accountValue_08, 1, 1) <> 'P') THEN
        v_isDocControlled_08 := (SELECT zsfi_get_c_elementvalue(p_ad_org_id, v_accountValue_08, 'isDocControlled'));
      END IF;
      IF (v_isDocControlled_07 = 'Y') OR (v_isDocControlled_08 = 'Y') THEN
        v_isDocControlled := 'Y';
      END IF;
      IF (v_isDocControlled = 'Y') THEN
      -- RAISE NOTICE '335 v_isDocControlled=%, v_isGross=%, v_SkontoAmt=%, v_accountValue_07=%, v_accountValue_08=%', v_isDocControlled, v_isGross, v_SkontoAmt, v_accountValue_07, v_accountValue_08;
      -- zunaechst Schnellschuss, da es auch Automatikkonten ohne Steuer gibt (v_isDocControlled bedeutut nicht 'Steuer 19% berechnen', auch 7% moeglich)
        v_c_tax_id := (SELECT zsfi_get_c_tax_id(v_ad_client_id , '9'));  -- c_tax, ad_client
        IF (NOT isempty(v_c_tax_id)) THEN
          v_isGross := 'Y';      -- Brutto, enthaelt Steuer
        END IF;
      END IF;

     -- Pruefung Steuerschluessel c_tax.c_tax_id immer prüfen (geliefert oder nicht geliefert (NOT NULL, Eintrag erforderlich)
      IF (v_c_tax_id IS NULL ) THEN
        v_anzError := v_anzError + 1;
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ', Spalte il_09: Steuerschluessel nicht im Steuerschluesselstamm gefunden';
        v_messArray[v_anzError] := v_message;
        CONTINUE;
      END IF;
     
     -- Kontentyp Spalte il_07
      IF (LENGTH(CUR_Lines.il_07) < v_acctlen) THEN -- fehlende fuehrende '0' bei Sachkonto ergaenzen
        v_accounttype_07 := zsfi_get_c_elementvalue(p_ad_org_id, LPAD(CUR_Lines.il_07, v_acctlen, '0'), 'accounttype'); -- '675' >> '0675'
      ELSEIF( (LENGTH(CUR_Lines.il_07) = 5) AND (SUBSTRING(CUR_Lines.il_07, 1, 1) = '1') ) THEN
        v_accounttype_07 := 'P';  -- Debitor  10000-69999
      ELSEIF( (LENGTH(CUR_Lines.il_07) = 5) AND (SUBSTRING(CUR_Lines.il_07, 1, 1) = '7') ) THEN
        v_accounttype_07 := 'P';  -- Kreditor 70000-99999
      ELSE
        v_accounttype_07 := zsfi_get_c_elementvalue(p_ad_org_id, CUR_Lines.il_07, 'accounttype');
      END IF;
     -- Zusammenfassung Kontentypen il_07
      IF ( (v_accounttype_07 = 'E') OR (v_accounttype_07 = 'R')  ) THEN
        v_accounttype_07 := 'GUVKTO';
      ELSEIF(v_accounttype_07 = 'P') THEN
        v_accounttype_07 := 'PERKTO';
      ELSE
        v_accounttype_07 := 'BILKTO';
      END IF;

     -- Kontentyp Spalte il_08
      IF (LENGTH(CUR_Lines.il_08) < v_acctlen) THEN -- fehlende fuehrende '0' bei Sachkonto ergaenzen
        v_accounttype_08 := zsfi_get_c_elementvalue(p_ad_org_id, LPAD(CUR_Lines.il_08, v_acctlen, '0'), 'accounttype');   -- '675' >> '0675'
      ELSEIF( (LENGTH(CUR_Lines.il_08) = v_acctlen+1) AND (SUBSTRING(CUR_Lines.il_08, 1, 1) = '1') ) THEN
        v_accounttype_08 := 'P';  -- Debitor  10000-69999
      ELSEIF( (LENGTH(CUR_Lines.il_08) = v_acctlen+1) AND (SUBSTRING(CUR_Lines.il_08, 1, 1) = '7') ) THEN
        v_accounttype_08 := 'P';  -- Kreditor 70000-99999
      ELSE
        v_accounttype_08 := zsfi_get_c_elementvalue(p_ad_org_id, CUR_Lines.il_08, 'accounttype'); -- SKTO(4)
      END IF;

     -- Zusammenfassung Kontentypen il_08
      IF ( (v_accounttype_08 = 'E') OR (v_accounttype_08 = 'R')  ) THEN
        v_accounttype_08 := 'GUVKTO';
      ELSEIF(v_accounttype_08 = 'P') THEN
        v_accounttype_08 := 'PERKTO';
      ELSE
        v_accounttype_08 := 'BILKTO';
      END IF;

      -- 23.04.2012 -- Verarbeitungsmatrix
      v_datevType := 0; -- nicht verarbeitet
      v_calcType  := 0; -- nicht verarbeitet

-- 1/4: S/H-Kennzeichen 'S' sowie 'nicht Umkehrbuchung'
      IF (    (CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'PERKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 1;
        -- 601,06	S	7	561,74	6130	75308	8	561,74	Mios
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr   := 'Y';
        v_calcType  := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'BILKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 2;
        -- 5404,98	S	19	6313	3500	9	4542,00	GSG GOSERIEDE, Miete
        -- 261,95;"S";"";;;"";6430;3500;"";1004;"";"";;"KUENSTLERSOZIALKASSE"
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr   := 'Y';
        v_calcType  := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'GUVKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 3;
        v_calcType  := (v_datevType * -1);
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'GUVKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 4;
        -- 27,42;S;;;;;75905;6851;94;2410;6372/11;;;11 Apple, 2x Programme, GS Rechnungskorektur; -- 201112_00_dez_all_6851_Kleingeraete.csv
        -- 20,93;S;;;;;74404;6700;9;2411;6604523009;;;9 DHL, GS -- Nov 2011
        --  P74404 20,93 an 6700 Kost.d.Wareabgabe 17,59, 3806 3,34 02.05.12
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'BILKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 5;
        v_calcType  := (v_datevType * -1);
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'PERKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 6;
        -- 536,13;S;;;;;135;74308;9;;;;;Cancom
        -- 668,67;S;;;;;1800;12502;;;;;;Paracelsus Klinik
        -- 170,41;S;;;;;1800;74811;;;;;;Hays;
        -- 725;S;;;;;135;75501;94;;;;;Passionned Group, BI Report Survey 2012 Full Edition
        -- 218,48;S;;;;;1860;12403;;501;100217;;;;;;;;;              ohne Buchungstext
        h_acctcr_id := v_acctcr_id; -- 25.04.
        v_acctcr_id := v_acctdr_id; -- 25.04.
        v_acctdr_id := h_acctcr_id; -- 25.04.
        v_isdr2cr  := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'GUVKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 7;
        /* 02.05. wieder deaktiviert wg 12.2011
        -- 362;S;;;;;3790;6140;;;;;;Betr.AV.An Lfd.Geh.Ver
        -- 88;S;;;;;3790;6140;;;;;;Betr.AV.An Lfd.Geh.Ver;
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'Y';
        */
        -- 19,75;S;;;;;1860;6815;9;1912;105865;A220;;Grambeck, Skt. -- 201112_02_dez_Kosten1.csv
        -- 357,00;"S";"";;;"";1870;4401;"";1004;"";"";;"Rossmann, NK-VZ"   -- DTVF_Buchungsstapel_20120613_120116_2.csv 2012.04
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'BILKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 8;
        -- 350,00;"S";"";;;"";3790;1341;"";3005;"201205";"";;"Darlehensrückzahlung / DTVF_Buchungsstapel_20120705_164305_all_1341.CSV 2012.05 / vgl. v_datevType := 32: GUmK;
        v_calcType := (v_datevType);

-- 2/4: S/H-Kennzeichen 'S' sowie 'ist Umkehrbuchung'
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'PERKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 9;
        -- 137,5	S		137,50	6300	75501	20	137,50	Passionned Group, Keine Re. 9 -- 02.2012
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_amt  := to_number(REPLACE(CUR_Lines.il_01, ',', '.') );  --REPLACE(il_01,',','.') -- UmkB-Betrag nicht negativ
        v_isdr2cr := 'Y';
        v_calcType := v_datevType; -- normale Buchung statt Umkehrbuchung
        v_calcType := v_datevType; -- normale Buchung statt Umkehrbuchung
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'BILKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 10;
        v_calcType := (v_datevType * -1);
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'GUVKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 11;
        v_calcType := (v_datevType * -1);
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'GUVKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 12;

   /* verworfen
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'N';
        -- (1) 6497 -2500,00 an (2) P74101 -2500,00
*/
        -- 2500;S;;;;;74101;6497;34;;;;;9 Generalumkehr   27.04.12, 34=nicht steuerpflichtig
        -- (2) 6497 -2500,00 an (1) P74101 -2500,00  -- 02.05.2012
        -- 158;S;;;;;75905;6851;29;510;6372/10;;;9 Generalumkehr; Steuer -- 201112_00_dez_all_6851_Kleingeraete.csv
        -- (1) 6851 -132,77, 1406 -25,23 an (1) P75905 -158,00  -- 02.05.2012
        v_isdr2cr := 'Y'; -- 02.05.12
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'BILKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 13;
        -- 530,69;S;;;;;74105;1370;20;310;51008/10;;;Generalumkehr 11.2011: nicht getestet ??
        -- 1496,74;"S";"";;;"";74105;1372;"20";0601;"51008/02";"";;"Generalumkehr / DTVF_Buchungsstapel_20120705_164305 2012.05 / vgl. calcType=20
        -- RAISE NOTICE 'v_datevType=% v_isdr2cr=%, v_accountValue_07=%, v_accountValue_08=%', v_datevType, v_isdr2cr, v_accountValue_07, v_accountValue_08;
        v_isdr2cr := 'N'; --
        v_calcType := (v_datevType);
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'PERKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 14;
        v_calcType := (v_datevType * -1);
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'GUVKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 15;
        -- 1195,00;"S";"";;;"";1600;6810;"29";2803;"50655";"";;"Generalumkehr"   2012.04
        v_isdr2cr := 'Y'; -- 04.07.2012
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'S') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'BILKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 16;
        -- 724,30;"S";"";;;"";1860;1370;"20";1904;"";"A66";;"Generalumkehr
        -- 1059,64;"S";"";;;"";1800;1370;"20";0905;"";"A90";;"Generalumkehr" / DTVF_Buchungsstapel_20120705_164305_all.CSV / 2012.05
        -- RAISE NOTICE 'v_datevType=% v_isdr2cr=%, v_accountValue_07=%, v_accountValue_08=%', v_datevType, v_isdr2cr, v_accountValue_07, v_accountValue_08;
        v_isdr2cr := 'N';
        v_calcType := (v_datevType);

-- 3/4: S/H-Kennzeichen 'H' sowie 'nicht Umkehrbuchung'
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'PERKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 17;
        -- 1943,23	H		19	-1632,97	6805	75803	9	-1632,97	Telekom 03/2012, GS                       12_feb_Kosten.csv
        --   137,5	H		 0   -137,50	6300	75501 0	 -137,50	Passionned Group, VAT Erst.               12_feb_Kosten.csv
        --  59,50;"H";"";;;"";4400;11201;"";3004;"101051";"";;"Dr. med. "
        -- 140,06;"H";"";;;"";4569;74220;"";3004;"A1200173";"";;"BWH,GS Vermitlungsprov. Broschüre"??   DTVF_Buchungsstapel_20120613_120116_4569_Prov.csv
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'N';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'BILKTO') AND (NOT v_isGUmkB) ) THEN
      -- 620000,00;"H";"";;;"";4818;1095;"";3004;"";"";;"Anpassung
        v_datevType := 18;
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'GUVKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 19;
        -- 1500,00;"H";"";;;"";4845;6393;"";0205;"0205";"";;"Schulverein, Spende Computer-Hardware
        -- RAISE NOTICE 'v_datevType=% v_isdr2cr=%, v_accountValue_07=%, v_accountValue_08=%', v_datevType, v_isdr2cr, v_accountValue_07, v_accountValue_08;
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'N';
        v_calcType := (v_datevType); -- 10.07.2012: 6393 1500 an 4845 1260,50, an 3806 239,50
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'GUVKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 20;
        -- 79,00	H	19	66,39	74508	6810	9	66,39	1&1 Intenet / 19%
        -- 1496,74;"H";"";;;"";74105;5900;"";0601;"51008/02";"";;"Holiday Villa, Doh -- DTVF_Buchungsstapel_20120705_164305_all.CSV 2012.05 (ohne Steuer)
        -- RAISE NOTICE 'v_datevType=% v_isdr2cr=%, v_accountValue_07=%, v_accountValue_08=%', v_datevType, v_isdr2cr, v_accountValue_07, v_accountValue_08;
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'BILKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 21;
        -- 1204,98;H;;;;;75905;1372;;;;;;Redcoon         v_isdr2cr := 'Y';  -- 02.2012
        -- 350;H;;;;;75905;1460;;;;;;Visa 10.01. ?? = 1460 Geldtransit  an PKTO
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'PERKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 22;
        -- 637,52;H;;;;;1860;75602;;;RG...;;;Ra..  -- 02.2012
        -- 670;H;;;;;1860;74117;;;;;;Agen..
        -- 16233,15;H;;;;;3900;11902;3;;;;;Ja...
      /*
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'Y';
      */
      /*
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'N';
      */
        v_isdr2cr := 'Y'; -- 25.04.12
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'GUVKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 23;
        -- 27,49	H	7	25,69	1600	6130	8	25,69	E-Neukauf, WE-Arbeit
        -- 900;H;;;;;3790;6020;;;;;;Bereitschaftsdienst
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'BILKTO') AND (NOT v_isGUmkB) ) THEN
        v_datevType := 24;
        --  358,67;H;;;;;1800;3172;;;;;;Tilg. Darl.
        -- 1308,37;H;;;;;1800;3740;;;;;;Daimler BKK Lastschrift -- 24.04.12
      /* -- 24.04.12 deaktiviert
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'Y';
      */
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;

-- 4/4 S/H-Kennzeichen 'H' sowie 'ist Umkehrbuchung'
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'PERKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 25;
        -- 400,00	H	-1	7	-373,83	6130	75601	28	-373,83	Generalumkehr
        -- 7,59;H;USD;1,3014;5,83;EUR;6811;74123;34;;,;;;Generalumkehr
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'BILKTO') AND (v_isGUmkB) ) THEN
      -- 303,45;H;;;;;6347;3500;20;2010;;;;Generalumkehr Stapel 11.2011 // vgl. v_datevType=2: Umkehrbeispiel
        v_datevType := 26; -- bei Bilanzkonto Brutto nach Soll tauschen
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'GUVKTO') AND (v_accounttype_08 = 'GUVKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 27;
      -- 25,1;H;;;;;6640;4650;20;   Generalumkehr -- 02.2012
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'GUVKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 28;
        v_calcType := (v_datevType * -1);
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'PERKTO') AND (v_accounttype_08 = 'BILKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 29;
        v_calcType := (v_datevType * -1);
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'PERKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 30; -- Bilanzkonto mit Steuer-Automatik
        -- 862,75;H;;;;;135;75501;29;2002;2012A39;;;Passionned Group, neue Rechnung (Generalumkehr) -- 02.2012
        h_acctcr_id := v_acctcr_id;
        v_acctcr_id := v_acctdr_id;
        v_acctdr_id := h_acctcr_id;
        v_isdr2cr := 'Y';
        v_calcType := v_datevType;
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'GUVKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 31;
        -- 295,14;"H";"";;;"";1860;4840;"20";0805;"12242HMC0100";"A75";;"Generalumkehr 2012.05
        v_isdr2cr := 'N'; -- 10.07.2012
        v_calcType := (v_datevType);
      ELSEIF ((CUR_Lines.il_02 = 'H') AND (v_accounttype_07 = 'BILKTO') AND (v_accounttype_08 = 'BILKTO') AND (v_isGUmkB) ) THEN
        v_datevType := 32;
        -- 641,86;H;;;;;1860;1370;20;;;;;Generalumkehr  -- 02.2012
        -- 350,00;"H";"";;;"";3790;1341;"20";3005;"201205";"";;"Generalumkehr";;" -- DTVF_Buchungsstapel_20120705_164305_all_1341.CSV 2012.05
       -- v_isdr2cr := 'Y'; -- 09.07.2012 deaktiviert
        v_isdr2cr := 'N'; -- 09.07.2012 aktiviert
        v_calcType := v_datevType;
      END IF;

      IF (v_datevType = 0) THEN
        v_anzError := v_anzError + 1;
        v_message := 'Tabelle i_primanotaline, Zeile ' || i || ',             : Buchungsmuster zu KzSH=' || COALESCE(CUR_Lines.il_02, '?') ||
              ' / Konto: ' || CUR_Lines.il_07 || ' / Konto: ' || CUR_Lines.il_08 ||
              ' / Buchungsschluessel:' || COALESCE(CUR_Lines.il_09, '0') || ' nicht verarbeitet';
        v_messArray[v_anzError] := v_message;
        CONTINUE;
      END IF;
      -- RAISE NOTICE '655 v_isGross=%, v_SkontoAmt=%, v_accountValue_07=%, v_accountValue_08=%', v_isGross, v_SkontoAmt, v_accountValue_07, v_accountValue_08;
     -- Projekt, Kostenstelle, Projektaufgabe
     -- Kost2
     if v_kost2conf='KOSTVALUE'  then
        select a.a_asset_id into v_asset from a_asset a where a.value like CUR_Lines.il_38||'%' limit 1;
        if v_asset is null then 
            select a.a_asset_id into v_asset from a_asset a where CUR_Lines.il_38 like a.value||'%' limit 1;
        end if;
     end if;
     -- Kost1
     if v_kost1conf='PROJECTVALUE' or  v_kost1conf='PROJECTVALUEKOSTVALUE' or  v_kost1conf='KOSTVALUE'  then
        if  v_kost1conf!='KOSTVALUE' then
            select c_project_id into v_prj from c_project where value = CUR_Lines.il_37 limit 1;
            /*
            if v_prj is null then
                select c_project_id into v_prj from c_project where CUR_Lines.il_37 like value||'%' limit 1;
            end if;
            */
        end if;
        if v_prj is null and v_kost1conf!='PROJECTVALUE' then
            select a.a_asset_id into v_asset from a_asset a where a.value = CUR_Lines.il_37 limit 1;
            /*
            if v_asset is null then 
                select a.a_asset_id into v_asset from a_asset a where CUR_Lines.il_37 like a.value||'%' limit 1;
            end if;
            */
        end if;
     end if;
     -- Pruefung Kostenstelle/Projekt, wenn geliefert (NULL erlaubt)
     IF ( (CUR_Lines.il_38 IS NOT NULL) AND (LENGTH(CUR_Lines.il_38) > 0) and v_kost2conf='KOSTVALUE') THEN
        IF (v_asset IS NULL) THEN
          v_anzError := v_anzError + 1;
          v_message := 'Tabelle  Zeile ' || i || ', Kostenstelle/Projekt existiert nicht: ''' || CUR_Lines.il_38 || '''';
          v_messArray[v_anzError] := v_message;
        END IF;
     END IF;
     IF ( (CUR_Lines.il_37 IS NOT NULL) AND (LENGTH(CUR_Lines.il_37) > 0) ) THEN
        IF v_prj IS NULL and v_asset IS NULL THEN
          v_anzError := v_anzError + 1;
          v_message := 'Tabelle Zeile ' || i || ', Projekt/Kostenstelle existiert nicht : ''' || CUR_Lines.il_37 || '''';
          v_messArray[v_anzError] := v_message;
        END IF;
     END IF;
     -- Projektaufgabe über Kost2
     if v_kost2conf='PRJTASKSEQNO'  then
        begin
            select c_projecttask_id into v_prt from c_projecttask where c_project_id=v_prj and seqno=to_number(CUR_Lines.il_38) limit 1;
        exception
        when others then null;
        end;
     else
        select c_projecttask_id into v_prt from c_projecttask where c_project_id=v_prj and name like CUR_Lines.il_59||'%' limit 1;
     end if;
     -- wenn noch kein Fehler in gefunden
      IF (v_anzError = 0 ) THEN
        INSERT INTO zsfi_macctline (
          zsfi_macctline_id, zsfi_manualacct_id, ad_client_id, ad_org_id, isactive,
          created,  createdby,  updated,  updatedby,
          line, amt, isdr2cr, isgross, acctcr, acctdr, description, c_tax_id,
          processing, cancel, glstatus,
          c_project_id, c_projectphase_id, c_projecttask_id,
          a_asset_id,
          calcType, -- 2012-06-27,
          acctdate
        )
        VALUES (
          get_uuid(), v_zsfi_manualacct_id, v_ad_client_id, p_ad_org_id, v_isactive,
          v_created, v_createdby, v_created, v_createdby,
          v_line,        -- +1
          v_amt,         -- Betrag
          v_isdr2cr,     -- Konto getauscht
          v_isGross,     -- N=Netto, Y=Brutto, ggfls. Steuer berechnen
          v_acctcr_id,   -- Konto-ID
          v_acctdr_id,   -- Konto-ID (Gegenkonto)
          TRIM(SUBSTRING(v_description || ' ' ||  v_Beleginfo1, 1, 255)), -- Buchungstext (255), wg Anzeige verkuerzt
          v_c_tax_id,    -- NOT NULL
          'N',           -- processing,
          'N',           -- cancel,
          'OP',          -- glstatus, NOT NULL, OP=nicht gebucht
          v_prj,          -- project_id,
          NULL,          -- c_projectphase_id,
          v_prt,          -- c_projecttask_id,
          v_asset,  -- Kostenstelle
          v_calcType,     -- Kennzeichen Verarbeitungsmatrix / Berechnungstyp Import Datev-Primanota   -- 2012-06-27,
          coalesce(CUR_Lines.acctdate,v_16)
     -- ALTER TABLE public.zsfi_macctline ADD COLUMN calcType INTEGER DEFAULT 0;                      -- 2012-06-27
     -- COMMENT ON COLUMN public.zsfi_macctline.calctype IS 'Berechnungstyp Import Datev-Primanota';  -- 2012-06-27
        );
        v_line := v_line + 10;
        v_prj:=null;
        v_asset:=null;
        v_prt:=null;
      END IF;

      IF (v_mitSktonto) THEN
        -- Buchungsschluessel 3=USt19%:'4736' / 9=VSt19%:'5736' AND (v_isGross = 'Y')
        v_datevType := 33;
        -- 19298,01;"S";"";;;"";1860;11114;"3";0705;"100406";"A74";28,99;"AstraZen
        -- 9314,23;"S";"";;;"";1800;11602;"3";2505;"101161";"A101";190,09;"Flora
        -- SELECT zsfi_get_c_elementvalue('AE3637495E9E4EBFA7E766FE9B97893A', '4736', 'name'); -- Gewährte Skonti 19 % USt, 'BFAE5A0527FD40B3AB9F4E33A8A021B8'
        v_acctcr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, v_accountValue_07); -- Debitor-Konto
        IF    (v_il_09 = '3') THEN  -- Umsatzsteuer 19%
          v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, '4736');     -- Gewährte Skonti 19 % USt
          v_amt := (v_SkontoAmt * -1);                                        -- negativer Ertrag
        ELSEIF (v_il_09 = '9') THEN  -- Vorsteuer 19%
          v_acctdr_id := zsfi_get_c_elementvalue_id(p_ad_org_id, '5736');     -- Erhaltene Skonti 19% Vorsteuer
          v_amt := v_SkontoAmt;                                               -- negativer Aufwand
        END IF;

        v_isGross := 'Y';  -- N=Netto, Y=Brutto, ggfls. Steuer berechnen
        v_isdr2cr := 'N';
        v_calcType := v_datevType;
        IF ( NOT isempty(v_acctcr_id) AND NOT isempty(v_acctdr_id) AND (v_amt <> 0) ) THEN
          -- Konto im SKR gefunden (via zsfi_get_c_elementvalue_id)
          -- RAISE NOTICE 'v_isGross=%, v_SkontoAmt=%, v_accountValue_07=%, v_accountValue_08=%', v_isGross, v_SkontoAmt, v_accountValue_07, v_accountValue_08;
          INSERT INTO zsfi_macctline (
            zsfi_macctline_id, zsfi_manualacct_id, ad_client_id, ad_org_id, isactive,
            created,  createdby,  updated,  updatedby,
            line, amt, isdr2cr, isgross, acctcr, acctdr, description, c_tax_id,
            processing, cancel, glstatus,
            c_project_id, c_projectphase_id, c_projecttask_id,
            a_asset_id,
            calcType -- 2012-06-27
          )
          VALUES (
            get_uuid(), v_zsfi_manualacct_id, v_ad_client_id, p_ad_org_id, v_isactive,
            v_created, v_createdby, v_created, v_createdby,
            v_line,        -- +1
            v_amt,         -- Betrag
            v_isdr2cr,     -- Konto getauscht
            v_isGross,     -- N=Netto, Y=Brutto, ggfls. Steuer berechnen
            v_acctcr_id,   -- Konto-ID
            v_acctdr_id,   -- Konto-ID (Gegenkonto)
            TRIM(SUBSTRING(SUBSTRING(v_description, 1, 45) || ' ' ||  v_Beleginfo1, 1, 50)), -- Buchungstext (255), wg Anzeige verkuerzt
            v_c_tax_id,    -- NOT NULL
            'N',           -- processing,
            'N',           -- cancel,
            'OP',          -- glstatus, NOT NULL, OP=nicht gebucht
            v_prj,          -- project_id,
            NULL,          -- c_projectphase_id,
            v_prt,          -- c_projecttask_id,
            v_asset,  -- Kostenstelle
            v_calcType     -- Kennzeichen Verarbeitungsmatrix / Berechnungstyp Import Datev-Primanota   -- 2012-06-27
          );
          v_line := v_line + 1;
        END IF;
      END IF;

    END LOOP;
  END;

  -- wenn Fehler gefunden, Exception provozieren für Ausgabe Fehlermeldungen
  IF (v_anzError > 0 ) THEN
    RAISE EXCEPTION '%', 'Manueller Buchungsstapel aufgrund von Fehlern nicht erstellt'; -- > Exception-Handling
  ELSE
    v_message := 'SUCCESS - Buchungsstapel erstellt: ' || v_17 || ' / ' || v_16 || ' / ' ||  i || ' Buchungen eingefügt.'; -- DBB
    v_message := v_message  || '</br>' || v_importFilename;
    RAISE NOTICE '%', v_message;
    v_link := (SELECT zsse_htmldirectlink('../org.openbravo.zsoft.finance.GLBatch/GLBatchHeaderB67F4C4E5C064996B264A86E3622EF58_Edition.html', 'document.frmImport.inpzsfiManualacctId', v_zsfi_manualacct_id, v_documentno));
    v_message := v_message  || '</br>' || v_link || '<Input type="hidden" name="inpzsfiManualacctId" value="' || v_zsfi_manualacct_id || '">';
    RETURN v_message;
  END IF;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;

   -- Fehlermeldungen ausgeben
    j := 0;
    LOOP
      IF (v_messArray[j] IS NOT NULL) THEN
        v_message := v_message || '</br>' || v_messArray[j];
      ELSE
        EXIT;
      END IF;
      j := j + 1;
    END LOOP;
    RAISE NOTICE '%', replace(v_message,'</br>',E'\r\n');
    RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION public.zsfi_get_c_elementvalue (
  p_ad_org_id varchar,
  p_c_elementvalue_value varchar,
  p_columnname varchar
)
RETURNS varchar AS
$body$
-- SELECT zsfi_get_c_elementvalue('AE3637495E9E4EBFA7E766FE9B97893A', '4569', 'isDocControlled') AS zsfi_c_elementvalue_isDocControlled; -- 'Y'
-- SELECT zsfi_get_c_elementvalue('AE3637495E9E4EBFA7E766FE9B97893A', '4569', 'accounttype') AS zsfi_c_elementvalue_accounttype; -- 'R' GuV
-- SELECT zsfi_get_c_elementvalue('AE3637495E9E4EBFA7E766FE9B97893A', '1341', 'name') AS zsfi_c_elementvalue_name; -- 'R' GuV
-- SELECT zsse_DropFunction('zsfi_get_c_elementvalue_accounttype');
DECLARE
  v_result               VARCHAR;

  v_org_ad_org_id        VARCHAR := '';
  v_org_isactive         VARCHAR := ''; -- N , Y
  v_oas_c_acctschema_id  VARCHAR := '';
  v_oas_isactive         VARCHAR := ''; -- N , Y
  v_ase_c_acctschema_id  VARCHAR := '';
  v_ase_isactive         VARCHAR := ''; -- N , Y
  v_ev_c_elementvalue_id VARCHAR := '';
  v_ev_isactive          VARCHAR := ''; -- N , Y
  v_ev_value             VARCHAR := ''; -- '1200'
  v_ev_name              VARCHAR;

  v_ev_accounttype       VARCHAR;
  v_ev_isDocControlled   VARCHAR;       -- '4569', SKR04
BEGIN
  SELECT
    org.ad_org_id, org.isactive,
    oas.c_acctschema_id, oas.isactive,
    ase.c_acctschema_id, ase.isactive,
    ev.c_elementvalue_id, ev.value, ev.isactive, ev.accounttype, ev.name, ev.isdoccontrolled
  INTO
    v_org_ad_org_id, v_org_isactive,
    v_oas_c_acctschema_id, v_oas_isactive,
    v_ase_c_acctschema_id, v_ase_isactive,
    v_ev_c_elementvalue_id, v_ev_value, v_ev_isactive, v_ev_accounttype, v_ev_name, v_ev_isDocControlled
  FROM
    AD_ORG org, ad_org_acctschema oas, c_acctschema_element ase, c_elementvalue ev
  WHERE 1=1
   AND oas.ad_org_id = org.ad_org_id
   AND ase.c_acctschema_id = oas.c_acctschema_id
   AND ev.c_element_id = ase.c_element_id
   AND org.ad_org_id = p_ad_org_id         -- 'AE3637495E9E4EBFA7E766FE9B97893A'
   AND ev.value = p_c_elementvalue_value;  -- '1200'

  IF ( (v_ev_c_elementvalue_id IS NOT NULL) AND (v_ev_value IS NOT NULL) )  THEN
    IF ( (v_org_isactive = 'Y')
     AND (v_oas_isactive = 'Y')
     AND (v_ase_isactive = 'Y')
     AND (v_ev_isactive  = 'Y') ) THEN

      IF (LOWER(p_columnName) = LOWER('accounttype')) THEN
       IF (LENGTH(v_ev_accounttype) > 0) THEN
         v_result :=  v_ev_accounttype;
       END IF;
      ELSEIF (LOWER(p_columnName) = LOWER('isDocControlled')) THEN
        v_result :=  v_ev_isDocControlled;
      ELSEIF (LOWER(p_columnName) = LOWER('c_elementvalue_id')) THEN
        v_result := v_ev_c_elementvalue_id;
      ELSEIF (LOWER(p_columnName) = LOWER('name')) THEN
        v_result := v_ev_name;
      END IF;

     END IF;
  END IF;

  RETURN v_result;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsfi_get_c_elementvalue_id (
    p_ad_org_id             CHARACTER VARYING,   -- ad_org_id.ad_org_id
    p_c_elementvalue_value  CHARACTER VARYING    -- c_elementvalue.value= '1200'
  )
RETURNS
  CHARACTER VARYING -- c_elementvalue_id
AS $body_$
-- SELECT zsfi_get_c_elementvalue_id('AE3637495E9E4EBFA7E766FE9B97893A', '1200') AS zsfi_c_elementvalue_id;  -- gueltig
-- SELECT zsfi_get_c_elementvalue_id('AE3637495E9E4EBFA7E766FE9B97893A', '1200') AS zsfi_c_elementvalue_id;  -- gueltig
-- SELECT zsfi_get_c_elementvalue_id('AE3637495E9E4EBFA7E766FE9B97893A', '12990') AS zsfi_c_elementvalue_id; -- ungueltig
-- SELECT * FROM c_elementvalue ev WHERE ev.value = '12990'; -- test

DECLARE
  v_result               character varying;

  v_org_ad_org_id        VARCHAR := '';
  v_org_isactive         VARCHAR := ''; -- N , Y
  v_oas_c_acctschema_id  VARCHAR := '';
  v_oas_isactive         VARCHAR := ''; -- N , Y
  v_ase_c_acctschema_id  VARCHAR := '';
  v_ase_isactive         VARCHAR := ''; -- N , Y
  v_ev_c_elementvalue_id VARCHAR := '';
  v_ev_isactive          VARCHAR := ''; -- N , Y
  v_ev_value             VARCHAR := ''; -- '1200'
BEGIN
  SELECT
    org.ad_org_id, org.isactive,
    oas.c_acctschema_id, oas.isactive,
    ase.c_acctschema_id, ase.isactive,
    ev.c_elementvalue_id, ev.value, ev.isactive  -- ev.name
  INTO
    v_org_ad_org_id, v_org_isactive,
    v_oas_c_acctschema_id, v_oas_isactive,
    v_ase_c_acctschema_id, v_ase_isactive,
    v_ev_c_elementvalue_id, v_ev_value, v_ev_isactive
  FROM
    AD_ORG org, ad_org_acctschema oas, c_acctschema_element ase, c_elementvalue ev
  WHERE 1=1
   AND oas.ad_org_id = org.ad_org_id
   AND ase.c_acctschema_id = oas.c_acctschema_id
   AND ev.c_element_id = ase.c_element_id
   AND org.ad_org_id = p_ad_org_id        -- 'AE3637495E9E4EBFA7E766FE9B97893A'
   AND ev.value = p_c_elementvalue_value;  -- '1200'

  IF ( (v_ev_c_elementvalue_id IS NOT NULL) AND (v_ev_value IS NOT NULL) )  THEN
    IF ( (v_org_isactive = 'Y')
     AND (v_oas_isactive = 'Y')
     AND (v_ase_isactive = 'Y')
     AND (v_ev_isactive  = 'Y') ) THEN
       IF (LENGTH(v_ev_value) > 0) THEN
         v_result :=  v_ev_c_elementvalue_id;
       END IF;
     END IF;
  END IF;

  RETURN v_result;
END;
$body_$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zsfi_get_c_element_id (
  p_ad_org_id            VARCHAR
)
RETURNS VARCHAR AS
$mh$
-- SELECT zsfi_get_c_element_id('AE3637495E9E4EBFA7E766FE9B97893A');
-- SELECT * FROM c_element e WHERE e.c_element_id = 'D871D9715A904125974B545FC0FF0681'; -- SKR4 Standard Kontenrahmen
 DECLARE
  v_result               VARCHAR;

  v_org_ad_org_id        VARCHAR := '';
  v_org_isactive         VARCHAR := ''; -- N , Y
  v_oas_c_acctschema_id  VARCHAR := '';
  v_oas_isactive         VARCHAR := ''; -- N , Y
  v_ase_c_acctschema_id  VARCHAR := '';
  v_ase_isactive         VARCHAR := ''; -- N , Y

  v_ase_c_element_id     VARCHAR;

BEGIN -- 2012-06-27
  SELECT
      org.ad_org_id, org.isactive,
      oas.c_acctschema_id AS oas_c_acctschema_id, oas.isactive AS oas_isactive,
      ase.c_acctschema_id AS ase_c_acctschema_id, ase.c_element_id AS ase_c_element_id, ase.isactive AS ase_isactive
  INTO
      v_org_ad_org_id, v_org_isactive,
      v_oas_c_acctschema_id, v_oas_isactive,
      v_ase_c_acctschema_id, v_ase_c_element_id, v_ase_isactive
  FROM
    AD_ORG org, ad_org_acctschema oas, c_acctschema_element ase
  WHERE 1=1
   AND oas.ad_org_id = org.ad_org_id
   AND ase.c_acctschema_id = oas.c_acctschema_id
   AND org.ad_org_id = p_ad_org_id; -- 'AE3637495E9E4EBFA7E766FE9B97893A';

  IF (NOT isempty(v_ase_c_element_id)) THEN
    v_result :=  v_ase_c_element_id;
  END IF;

  RETURN v_result;
END ;
$mh$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zspr_Copy_Bwa2CSV (
  p_zspr_bwaheader_id CHARACTER VARYING    -- source
)
  RETURNS CHARACTER VARYING
AS $body_$
-- SELECT zspr_Copy_Bwa2CSV('3EF137267B2A44F69B32A881CBCD553A') AS zspr_bwaheader_CSV; -- 02_JuwiMM Kostenaufstellung BWA Detail
-- SELECT zspr_Copy_Bwa2CSV('D58A329A203847C799F190C6717F26C9') AS zspr_bwaheader_CSV; -- 02_JuwiMM BWA-Nr4 Detail GuV Staffelform
-- SELECT zspr_Copy_Bwa2CSV('3EF137267B2A44F69B32A881CBCD553B') AS zspr_bwaheader_id; -- Auswertung nicht gefunden
-- DROP FUNCTION public.zspr_Copy_Bwa2CSV(p_zspr_bwaheader_id varchar);
DECLARE
  i                     INTEGER := 0;

  v_messArray           VARCHAR[];      -- dyn. erweiterbares Array
  v_anzError            INTEGER := 0;   -- Überschrift für Fehlermeldung = v_messArray[0]
  v_cmd                 VARCHAR := '';
  v_message             VARCHAR := '';

  v_fileDateTime        VARCHAR;
  v_bwaheader_name      VARCHAR;
  v_outputFile1         VARCHAR;
  v_outputFile2         VARCHAR;
  v_outputFile3         VARCHAR;

BEGIN
  v_message := 'Folgende Fehler bei der Verarbeitung gefunden:';
  v_messArray[0] := v_message;
  v_fileDateTime := to_char(now(), 'YYYYMMDD_HH24MISS');

  SELECT h.name INTO v_bwaheader_name FROM zspr_bwaheader h WHERE h.zspr_bwaheader_id = p_zspr_bwaheader_id;
  IF (v_bwaheader_name IS NULL) THEN
    v_anzError := v_anzError + 1;
    v_message := '@ERROR = Auswertung nicht gefunden ';
    RETURN v_message;
  END IF;

  v_outputFile1 := '/tmp/' || v_bwaheader_name || '_' || 'zspr_bwaheader' || '_' || v_fileDateTime || '.sql';
  RAISE NOTICE 'v_outputFile1=%', v_outputFile1;
  v_cmd := 'COPY (SELECT * FROM zspr_bwaheader h WHERE h.zspr_bwaheader_id = ' || '''' || p_zspr_bwaheader_id || '''' || ')'
           ||' TO ' || '''' || v_outputFile1 || '''';
--RAISE NOTICE 'v_cmd=%', v_cmd;
  EXECUTE(v_cmd);
--  EXECUTE('COPY (SELECT * FROM zspr_bwaheader h WHERE h.zspr_bwaheader_id = ' || '''' || p_zspr_bwaheader_id || '''' || ')'
--           || ' TO ' || '''' ||  '/tmp/' || v_bwaheader_name || '_' || 'zspr_bwaheader' || '_' || v_fileDateTime || '.sql'   || '''');
-- COPY (SELECT * FROM zspr_bwaheader h WHERE h.zspr_bwaheader_id = p_zspr_bwaheader_id ) TO '/tmp/' || v_bwaheader_name || '_' || 'zspr_bwaheader' || '_' || v_fileDateTime || '.sql';
-- RETURN'';

  v_outputFile2 := '/tmp/' || v_bwaheader_name || '_' || 'zspr_bwaprefs' || '_' || v_fileDateTime || '.sql';
  v_cmd := 'COPY (SELECT * FROM zspr_bwaprefs p WHERE p.zspr_bwaheader_id = ' || '''' || p_zspr_bwaheader_id || '''' || ')'
           ||' TO ' || '''' || v_outputFile2 || '''';
  EXECUTE(v_cmd);
  RAISE NOTICE 'v_outputFile2=%', v_outputFile2;

  v_outputFile3 := '/tmp/' || v_bwaheader_name || '_' || 'zspr_bwaprefacct' || '_' || v_fileDateTime || '.sql';
  v_cmd := 'COPY (SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefs_id IN (SELECT zspr_bwaprefs_id FROM zspr_bwaprefs p ' ||
       ' WHERE p.zspr_bwaheader_id IN (SELECT zspr_bwaheader_id FROM zspr_bwaheader h ' ||
       ' WHERE h.zspr_bwaheader_id = ' || '''' || p_zspr_bwaheader_id || '''' || ')))' ||
       ' TO ' || '''' || v_outputFile3 || '''';
  EXECUTE(v_cmd);
  RAISE NOTICE 'v_outputFile3=%', v_outputFile3;

  -- wenn Fehler gefunden, Exception provozieren für Ausgabe Fehlermeldungen
  IF (v_anzError > 0 ) THEN
    RAISE EXCEPTION '%', 'BWA-Auswertung aufgrund von Fehlern nicht kopiert'; -- > Exception-Handling
  ELSE
    v_message := 'SUCCESS - BWA-Auswertung in CSV-Datei kopiert: ';
    v_message := v_message || '</br>' || v_outputFile1 || '</br>' || v_outputFile2 || '</br>' || v_outputFile3;
    RETURN v_message;
  END IF;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;

   -- Fehlermeldungen ausgeben
    i := 0;
    LOOP
      IF (v_messArray[i] IS NOT NULL) THEN
        v_message := v_message || '</br>' || v_messArray[i];
      ELSE
        EXIT;
      END IF;
      i := i + 1;
    END LOOP;
    RAISE NOTICE '%', REPLACE(v_message,'</br>',E'\r\n');
    RETURN v_message;
END;
$body_$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zspr_DROP_BWA (
  p_zspr_bwaheader_id VARCHAR    -- source
)
  RETURNS VARCHAR
AS $mh$
--SELECT * FROM  zspr_bwaheader p WHERE p.zspr_bwaheader_id = 'D58A329A203847C799F190C6717F26C9'; -- BWA.Nr.4
--SELECT * FROM  zspr_bwaprefs p WHERE p.zspr_bwaheader_id = 'D58A329A203847C799F190C6717F26C9';

-- SELECT zspr_DROP_BWA('D58A329A203847C799F190C6717F26C9') AS zspr_bwaheader_DropResult;
-- SELECT zspr_DROP_BWA('!!8A329A203847C799F190C6717F26C9') AS zspr_bwaheader_id; -- Auswertung nicht gefunden
-- DROP FUNCTION public.zspr_DROP_BWA(p_zspr_bwaheader_id varchar);
DECLARE
  i                     INTEGER := 0;

  v_messArray           VARCHAR[];      -- dyn. erweiterbares Array
  v_anzError            INTEGER := 0;   -- Überschrift für Fehlermeldung = v_messArray[0]
  v_cmd                 VARCHAR := '';
  v_message             VARCHAR := '';

  v_fileDateTime        VARCHAR;
  v_bwaheader_name      VARCHAR;
BEGIN
  v_message := 'Folgende Fehler bei der Verarbeitung gefunden:';
  v_messArray[0] := v_message;
  v_fileDateTime := to_char(now(), 'YYYYMMDD_HH24MISS');

  SELECT h.name INTO v_bwaheader_name FROM zspr_bwaheader h WHERE h.zspr_bwaheader_id = p_zspr_bwaheader_id;
  IF (v_bwaheader_name IS NULL) THEN
    v_anzError := v_anzError + 1;
    v_message := '@ERROR = Auswertung nicht gefunden ';
    RETURN v_message;
  END IF;

  RAISE NOTICE 'UPDATE zspr_bwaprefs p SET parentpref = NULL WHERE p.zspr_bwaheader_id=%', p_zspr_bwaheader_id;
  UPDATE zspr_bwaprefs p SET parentpref = NULL WHERE p.zspr_bwaheader_id = p_zspr_bwaheader_id; --'3EF137267B2A44F69B32A881CBCD553A';

  DECLARE
    CUR_prefs RECORD;
  BEGIN
    RAISE NOTICE 'SELECT zspr_bwaprefs_id, zspr_bwaheader_id FROM zspr_bwaprefs p WHERE p.zspr_bwaheader_id=% ORDER BY orderno', p_zspr_bwaheader_id;
    FOR CUR_Prefs IN (
      SELECT zspr_bwaprefs_id, zspr_bwaheader_id FROM zspr_bwaprefs p WHERE p.zspr_bwaheader_id = p_zspr_bwaheader_id ORDER BY orderno
      )
    LOOP
      DECLARE
        CUR_bwaprefacct RECORD;
      BEGIN
        FOR CUR_bwaprefacct IN (
          SELECT a.zspr_bwaprefacct_id, a.zspr_bwaprefs_id FROM zspr_bwaprefacct a WHERE a.zspr_bwaprefs_id = CUR_Prefs.zspr_bwaprefs_id ORDER BY acctmatch
          )
        LOOP
        --RAISE NOTICE 'DELETE FROM zspr_bwaprefacct a WHERE a.zspr_bwaprefs_id=%', CUR_Prefs.zspr_bwaprefs_id;
        --DELETE FROM zspr_bwaprefacct a WHERE a.zspr_bwaprefs_id = CUR_Prefs.zspr_bwaprefs_id;
          RAISE NOTICE 'DELETE FROM zspr_bwaprefacct a WHERE a.zspr_bwaprefacct_id=% (a.zspr_bwaprefs_id=%)', CUR_bwaprefacct.zspr_bwaprefacct_id, CUR_bwaprefacct.zspr_bwaprefs_id;
          DELETE FROM zspr_bwaprefacct WHERE zspr_bwaprefacct_id = CUR_bwaprefacct.zspr_bwaprefacct_id;
        END LOOP;
      END;
      RAISE NOTICE 'DELETE FROM zspr_bwaprefs WHERE pref.zspr_bwaprefs_id =%', CUR_Prefs.zspr_bwaprefs_id;
      DELETE FROM zspr_bwaprefs p WHERE p.zspr_bwaprefs_id = CUR_Prefs.zspr_bwaprefs_id;
    END LOOP;
  END;
  RAISE NOTICE 'DELETE FROM zspr_bwaheader WHERE zspr_bwaheader_id=%', p_zspr_bwaheader_id;
  DELETE FROM zspr_bwaheader WHERE zspr_bwaheader_id =  p_zspr_bwaheader_id;

  -- wenn Fehler gefunden, Exception provozieren für Ausgabe Fehlermeldungen
  IF (v_anzError > 0 ) THEN
    RAISE EXCEPTION '%', 'BWA-Auswertung aufgrund von Fehlern nicht geloescht'; -- > Exception-Handling
  ELSE
    v_message := 'SUCCESS - BWA-Auswertung geloescht';
    v_message := v_message;
    RETURN v_message;
  END IF;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;

   -- Fehlermeldungen ausgeben
    i := 0;
    LOOP
      IF (v_messArray[i] IS NOT NULL) THEN
        v_message := v_message || '</br>' || v_messArray[i];
      ELSE
        EXIT;
      END IF;
      i := i + 1;
    END LOOP;
    RAISE NOTICE '%', REPLACE(v_message,'</br>',E'\r\n');
    RETURN v_message;
END;
$mh$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION zspr_bwaprefacct_check (
  p_ad_org_id VARCHAR -- not accessible by GUI, SELECT on console only
)
-- SELECT zspr_bwaprefacct_check('AE3637495E9E4EBFA7E766FE9B97893A'); -- ORG -> SKR -> alle BWA's
-- SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in ('02B0AA733C61476091D9F4DC6D69E9FC', '052D9B86CC544F4F9A97FF7F39FFEAFD') -- 7144 - 7144
/*
SELECT -- Uebersicht doppelter Eintraege
  f.acctmatch, count(*)
--  f.*
FROM zspr_bwaprefacct f, zspr_bwaprefs p
WHERE  1=1
  AND f.zspr_bwaprefs_id = p.zspr_bwaprefs_id
  AND f.zspr_bwaprefs_id in (
-- SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in ('AE0BE787EF2D400C8E9236C39C42770E', 'CF3BF897AB4F49219CFC1B8EF7BDF8BB') -- <- WARNING-Statement der Konsole
   SELECT f.zspr_bwaprefs_id FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in ('98FA476AEBCB4C30B0C1638139CF1D13', '7BE21ED4D2644E9FA773B58ACA91BA15') -- f.zspr_bwaprefs_id
   )
--AND f.zspr_bwaprefs_id in ('8E1FEF229F76413C91A67EC46118C331', 'C80B7B25DE244061840025FFEE02FFA4')
GROUP BY f.acctmatch
HAVING COUNT(*) > 1
ORDER BY f.acctmatch DESC-- , p.orderno

*/

/*
SELECT -- Einzelnachweis für einen MatchCode (acctmatch) doppelte(=pruefen) und einzelne(=uebrige)
  p.zspr_bwaheader_id, p.zspr_bwaprefs_id, p.name, f.acctmatch, p.orderno
FROM zspr_bwaprefacct f, zspr_bwaprefs p
WHERE  1=1
  AND f.zspr_bwaprefs_id = p.zspr_bwaprefs_id
  AND f.zspr_bwaprefs_id in (
-- SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in ('AE0BE787EF2D400C8E9236C39C42770E', 'CF3BF897AB4F49219CFC1B8EF7BDF8BB') -- <- WARNING-Statement der Konsole
   SELECT f.zspr_bwaprefs_id FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in ('02B0AA733C61476091D9F4DC6D69E9FC', '052D9B86CC544F4F9A97FF7F39FFEAFD') -- f.zspr_bwaprefs_id: 7144 - 7144
   )
ORDER BY f.acctmatch DESC, p.orderno
*/

RETURNS VARCHAR AS
$mh$
DECLARE
  i INTEGER;
  j INTEGER;
  x INTEGER;

  s VARCHAR;
  k VARCHAR;
  o VARCHAR;

  v_anzError         INTEGER := 0;
  v_message          VARCHAR := '';

  v_parentpref       VARCHAR;
  v_acctmatch        VARCHAR;
  v_result           VARCHAR  := '';
  v_listKto          VARCHAR[9999];
  v_listOrt          VARCHAR[9999];

  v_zspr_bwaheader_id    VARCHAR;
  v_zspr_bwaprefs_id     VARCHAR;
  v_zspr_bwaprefacct_id  VARCHAR;
  v_c_element_id         VARCHAR;
  v_el_c_element_id      VARCHAR;
  v_el_element_name      VARCHAR;
  v_zspr_bwaheader_name  VARCHAR;
  v_zspr_bwaprefs_name   VARCHAR;

  cur_head           RECORD;
  cur_pref           RECORD;
  cur_acct           RECORD;
BEGIN

 -- Sachkontenrahmen pruefen
  v_c_element_id := (SELECT zsfi_get_c_element_id(p_ad_org_id)); -- D871D9715A904125974B545FC0FF0681 = SKR04
  IF isempty(v_c_element_id) THEN
    v_anzError := v_anzError + 1;
    v_message := '@ERROR=Sachkontenrahmen nicht gefunden zu ad_org_id=' || p_ad_org_id;
    RETURN v_message;
  END IF;

 -- Sachkontenrahmen ausgeben
  SELECT el.c_element_id, el.name INTO v_el_c_element_id, v_el_element_name FROM c_element el WHERE el.c_element_id = v_c_element_id;
  RAISE NOTICE 'Sachkontorahmen: %=%', v_el_c_element_id, v_el_element_name;

  FOR cur_head IN
   (SELECT hd.zspr_bwaheader_id, hd.name, hd.ad_org_id FROM zspr_bwaheader hd
    WHERE hd.zspr_bwaheader_id = 'D58A329A203847C799F190C6717F26C9') -- WHERE hd.ad_org_id = p_ad_org_id
  LOOP
    v_zspr_bwaheader_name := cur_head.name;
    v_zspr_bwaheader_id := cur_head.zspr_bwaheader_id;
    RAISE NOTICE 'v_zspr_bwaheader_id=%', v_zspr_bwaheader_id;

    FOR cur_pref IN
     (SELECT pr.zspr_bwaheader_id, pr.zspr_bwaprefs_id, pr.name FROM zspr_bwaprefs pr WHERE pr.zspr_bwaheader_id = v_zspr_bwaheader_id ORDER BY orderno)
    LOOP
      v_zspr_bwaheader_id := cur_pref.zspr_bwaheader_id;
      v_zspr_bwaprefs_id := cur_pref.zspr_bwaprefs_id;
      v_zspr_bwaprefs_name := cur_pref.name;
      RAISE NOTICE 'v_zspr_bwaheader_id=%, v_zspr_bwaprefs_id=%, v_zspr_bwaprefs_name=%', v_zspr_bwaheader_id, v_zspr_bwaprefs_id, v_zspr_bwaprefs_name;

      FOR cur_acct IN
       (SELECT pa.zspr_bwaprefacct_id, pa.acctmatch FROM zspr_bwaprefacct pa WHERE pa.zspr_bwaprefs_id = v_zspr_bwaprefs_id ORDER BY pa.acctmatch DESC) -- 494%, 4940
      LOOP
        v_zspr_bwaprefacct_id := cur_acct.zspr_bwaprefacct_id;
        v_acctmatch := cur_acct.acctmatch;
        RAISE NOTICE 'v_zspr_bwaprefs_id=%, v_zspr_bwaprefacct_id=%, v_acctmatch=%', v_zspr_bwaprefs_id, v_zspr_bwaprefacct_id, v_acctmatch;

        IF (SUBSTRING(v_acctmatch, 4, 1) = '%') THEN -- 440%
          FOR i IN 0..9 LOOP
            s := SUBSTR(v_acctmatch, 1, 3) || TRIM(to_char(i));
            x := to_number(s);
            IF (v_listKto[x] IS NOT NULL ) THEN
              k := v_listKto[x];
              o := v_listOrt[x];
              RAISE WARNING 'SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in (''%'', ''%'') -- %: % - %', v_zspr_bwaprefacct_id, o, v_zspr_bwaprefs_name, v_acctmatch, k;
              v_anzError := v_anzError + 1;
            ELSE
              v_listKto[x] := s;
              v_listOrt[x] := v_zspr_bwaprefacct_id;
            END IF;
          END LOOP;
        ELSEIF (SUBSTRING(v_acctmatch, 3, 1) = '%') THEN -- '43%'
          FOR i IN 0..99 LOOP
            s := SUBSTR(v_acctmatch, 1, 2) || LPAD( TRIM(to_char(i)), 2, '00');
            x := to_number(s);
            IF (v_listKto[x] IS NOT NULL ) THEN
              k := v_listKto[x];
              o := v_listOrt[x];
              RAISE WARNING 'SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in (''%'', ''%'') -- % - %', v_zspr_bwaprefacct_id, o, v_acctmatch, k;
              v_anzError := v_anzError + 1;
            ELSE
              v_listKto[x] := s;
              v_listOrt[x] := v_zspr_bwaprefacct_id;
            END IF;
          END LOOP;
        ELSEIF (SUBSTRING(v_acctmatch, 2, 1) = '%') THEN -- '4%'
          FOR i IN 0..999 LOOP
            s := SUBSTR(v_acctmatch, 1, 1) || LPAD( TRIM(to_char(i)), 3, '000'); -- '4000'
            x := to_number(s);
            IF (v_listKto[x] IS NOT NULL ) THEN
              k := v_listKto[x];
              o := v_listOrt[x];
              RAISE WARNING 'SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in (''%'', ''%'') -- % - %', v_zspr_bwaprefacct_id, o, v_acctmatch, k;
              v_anzError := v_anzError + 1;
            ELSE
              v_listKto[x] := s;
              v_listOrt[x] := v_zspr_bwaprefacct_id;
            END IF;
          END LOOP;
        ELSEIF (LENGTH(v_acctmatch) = 4) THEN
          s := v_acctmatch; -- '4000'
          x := to_number(s);
          IF (v_listKto[x] IS NOT NULL) THEN
              k := v_listKto[x];
              o := v_listOrt[x];
              RAISE WARNING 'SELECT * FROM zspr_bwaprefacct f WHERE f.zspr_bwaprefacct_id in (''%'', ''%'') -- % - %', v_zspr_bwaprefacct_id, o, v_acctmatch, k;
              v_anzError := v_anzError + 1;
          ELSE
            v_listKto[x] := v_acctmatch;
            v_listOrt[x] := v_zspr_bwaprefacct_id;
          END IF;
        END IF;
      END LOOP;

    END LOOP;

  END LOOP;

  IF (v_anzError > 0) THEN
    v_result := '@WARNING@' ||  ' ' || v_anzError || ' Warnungen gefunden - Ausgabe auf der Konsole pruefen';
  END IF;
  RETURN v_result;
END;

$mh$
LANGUAGE 'plpgsql';







CREATE OR REPLACE FUNCTION zsfi_generatesusadatev(p_pinstance_id character varying)
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
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Projects, UnDispose the complete BOM of the Task in Inventory
                  Cancel Task - Cancel PR, if open
Checks
*****************************************************/
v_Record_ID  character varying;

v_message character varying:='Sucess';
v_User varchar;
v_cur record;
v_org varchar;
v_datefrom date;
v_dateto date;
v_acctsh varchar;
BEGIN
    --  Update AD_PInstance
    PERFORM AD_UPDATE_PINSTANCE(p_PInstance_ID, NULL, 'Y', NULL, NULL) ;
    SELECT i.Record_ID, i.AD_User_ID into v_Record_ID, v_User from AD_PINSTANCE i WHERE i.AD_PInstance_ID=p_PInstance_ID;
    if v_Record_ID is null then
       RAISE NOTICE '%','Pinstance not found-Using as RecordID ' || p_PInstance_ID;
       v_Record_ID:=p_PInstance_ID;
       v_User:='0';
    end if;
    select d.ad_org_id,trunc(d.datefrom),trunc(d.dateto),oc.c_acctschema_id into  v_org,v_datefrom,v_dateto,v_acctsh 
    from zsfi_susadatev d,ad_org_acctschema oc where oc.ad_org_id=d.ad_org_id and d.zsfi_susadatev_id=v_Record_ID;
    delete from zsfi_susadatevaccounts where zsfi_susadatev_id=v_Record_ID;
    --
    for v_cur in (SELECT  F.ACCOUNT_ID AS ACCOUNT_ID, EV.NAME AS NAME, EV.VALUE AS ACCOUNTvalue,
                  zsfi_GetBalanceAtTime(f.ad_org_id, v_acctsh, f.account_id, v_datefrom) AS SALDO_INICIAL,
          zsfi_GetBalanceAtTime(f.ad_org_id, v_acctsh, f.account_id, v_datefrom) + zsfi_GetBalanceAmount(f.ad_org_id, v_acctsh, f.account_id, v_datefrom,v_dateto) AS saldo_final,
          SUM((CASE f.FACTACCTTYPE WHEN 'O' THEN 0 ELSE f.AMTACCTCR END)) AS AMTACCTCR_soll,
          SUM((CASE f.FACTACCTTYPE WHEN 'O' THEN 0 ELSE F.AMTACCTDR END)) AS AMTACCTDR_haben 
        FROM FACT_ACCT F, C_ELEMENTVALUE EV
        WHERE F.ACCOUNT_ID = EV.C_ELEMENTVALUE_ID
          AND f.AD_ORG_ID = v_org   AND F.FACTACCTTYPE <> 'R'  AND F.FACTACCTTYPE <> 'C'  AND F.ISACTIVE = 'Y'
          and f.dateacct between v_datefrom and v_dateto
          and EV.VALUE not like '9%'
        GROUP BY f.ad_org_id, f.account_id, ev.name, ev.value)
    LOOP
        if (select count(*) from zsfi_susadatevaccounts where zsfi_susadatev_id=v_Record_ID and name=v_cur.ACCOUNTvalue)>0 then
            update zsfi_susadatevaccounts set c_elementvalue_id=v_cur.ACCOUNT_ID,BeginningBalance=v_cur.SALDO_INICIAL,
                   EndingBalance=v_cur.saldo_final,debit=v_cur.AMTACCTDR_haben,credit=v_cur.AMTACCTCR_soll,
                   updated=now(),updatedby=v_User
            where zsfi_susadatev_id=v_Record_ID and name=v_cur.ACCOUNTvalue;
        else
            insert into ZSFI_SUSADATEVACCOUNTS(ZSFI_SUSADATEVACCOUNTS_ID, ZSFI_SUSADATEV_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME, C_ELEMENTVALUE_ID,
                                                BEGINNINGBALANCE, ENDINGBALANCE, DEBIT, CREDIT)
            values (get_uuid(),v_Record_ID,'C726FEC915A54A0995C568555DA5BB3C',v_org,v_User,v_User,v_cur.ACCOUNTvalue,v_cur.ACCOUNT_ID,
                    v_cur.SALDO_INICIAL,v_cur.saldo_final,v_cur.AMTACCTDR_haben,v_cur.AMTACCTCR_soll);
        end if;
    END LOOP;
    --  Update AD_PInstance
    RAISE NOTICE '%','Updating PInstance - Finished ';
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
  
  
  
  
  
  
  
CREATE or replace FUNCTION zsdv_InsertDatevImport_SuSa (
  p_filename VARCHAR,
  p_user VARCHAR,
  p_susadatevid VARCHAR
)
  RETURNS VARCHAR
AS $body_$
-- SELECT zsdv_insertDatevImport_01('/tmp/DTVF_Buchungsstapel.csv') as plresult from dual;
DECLARE
  v_cur RECORD;
  i INTEGER := 0;
  v_anzLines INTEGER := 0;
  v_id varchar;

  j INTEGER;
  v_header VARCHAR;
  v_headerLine VARCHAR;
  v_pos INTEGER := 0;
  v_sem INTEGER := 0;

  v_cmd VARCHAR := '';
  v_message VARCHAR := '';
  v_saldo numeric;
  v_negative varchar;
  v_accounttype varchar;
  v_ozsaldo numeric;
  v_evid varchar;
  v_actval varchar;
  v_acctsh varchar;
  v_datefrom date;
  v_dateto date;
  v_org varchar;
  v_User varchar;
  v_acctlen integer;
BEGIN

if p_filename is null then
    return '';
end if;

  IF NOT EXISTS(
    SELECT relname FROM pg_class
    WHERE UPPER(relname) =  UPPER('I_SuSa') AND relkind = 'r') THEN
    RAISE NOTICE 'CREATE TABLE I_SuSa';
    -- DROP TABLE I_Primanota;
    CREATE TABLE I_SuSa (
      i_01 VARCHAR(100),   -- "Konto"
      i_02 VARCHAR(040),   -- Konto Name
      i_03 VARCHAR(030),   -- EB Wert
      i_04 VARCHAR(270),   -- S
      i_05 VARCHAR(020),   -- H
      i_06 VARCHAR(180),   -- Saldo
      i_07 VARCHAR(270),   -- S
      i_08 VARCHAR(030),   -- H
      i_09 VARCHAR(270),   -- Soll
      i_10 VARCHAR(270),   -- Haben
      i_11 VARCHAR(100),   -- Kum. Soll
      i_12 VARCHAR(100)    -- Kum. Haben
    ) WITHOUT OIDS; -- SELECT * FROM I_Primanota
  ELSE
    TRUNCATE TABLE I_SuSa;
  END IF;
  select trunc(to_number(VALUE)) into  v_acctlen from ad_preference where attribute='DATEVACCTLEN';
-- Kopfsatz kopieren
  v_cmd := 'COPY I_SuSa FROM ''' || p_filename ||'''  CSV DELIMITER AS '';'' NULL AS ''NULL'' QUOTE AS ''"''' ;
  RAISE NOTICE '%', v_cmd;
  EXECUTE(v_cmd);
  v_cmd := 'EXECUTE(v_cmd)';
  update i_susa set i_06=replace(i_06,'.',''),i_09=replace(i_09,'.',''),i_10=replace(i_10,'.',''),
                    i_11=replace(i_11,'.',''),i_12=replace(i_12,'.',''),i_03=replace(i_03,'.','');
  update i_susa set i_04=i_05 where coalesce(i_04,'')='';
  update i_susa set i_07=i_08 where coalesce(i_07,'')='';
  update i_susa set i_12='0' where coalesce(i_12,'')='';
  update i_susa set i_11='0' where coalesce(i_11,'')='';
  update i_susa set i_06='0' where coalesce(i_06,'')='';
  update i_susa set i_01 = replace(i_01,' ','');
  for v_cur in (select * from i_susa where (length(i_01)=v_acctlen and i_01 not like '9%' and i_01!='1400' and i_01!='1600') or length(i_01)!=v_acctlen)
  LOOP
    select zsfi_susadatevaccounts_id,c_elementvalue_id into v_id,v_evid from zsfi_susadatevaccounts where lpad(name,(v_acctlen+1),'0')=lpad(v_cur.i_01,(v_acctlen+1),'0') 
           and zsfi_susadatev_id=p_susadatevid;
    if v_id is null then
       select get_uuid() into  v_id;  
       select C_ELEMENTVALUE.C_ELEMENTVALUE_ID,C_ELEMENTVALUE.value,ad_org_acctschema.c_acctschema_id ,ZSFI_SUSADATEV.datefrom,ZSFI_SUSADATEV.dateto ,
              ZSFI_SUSADATEV.ad_org_id,ZSFI_SUSADATEV.updatedby
              into v_evid , v_actval,v_acctsh,v_datefrom,v_dateto,v_org,v_User
              from C_ELEMENTVALUE,C_ELEMENT,c_acctschema_element,ad_org_acctschema,ZSFI_SUSADATEV where
              lpad(C_ELEMENTVALUE.value,(v_acctlen+1),'0')=lpad(v_cur.i_01,(v_acctlen+1),'0') and C_ELEMENTVALUE.C_ELEMENT_id=C_ELEMENT.C_ELEMENT_id and
              c_acctschema_element.C_ELEMENT_id=C_ELEMENT.C_ELEMENT_id and ad_org_acctschema.c_acctschema_id=c_acctschema_element.c_acctschema_id and
              ad_org_acctschema.ad_org_id=ZSFI_SUSADATEV.ad_org_id and ZSFI_SUSADATEV.ZSFI_SUSADATEV_id=p_susadatevid;
       if v_evid is null then
        raise exception '%', 'Abstimmung kann nicht durchgeführt werden. Konto '||v_cur.i_01||' nicht in OpenZ vorhanden.';
       end if;
       insert into ZSFI_SUSADATEVACCOUNTS(ZSFI_SUSADATEVACCOUNTS_ID, ZSFI_SUSADATEV_ID, AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY, NAME, C_ELEMENTVALUE_ID,
                                                BEGINNINGBALANCE, ENDINGBALANCE, DEBIT, CREDIT)
       values (v_id,p_susadatevid,'C726FEC915A54A0995C568555DA5BB3C',v_org,v_User,v_User,v_actval,v_evid,
               zsfi_GetBalanceAtTime(v_org, v_acctsh, v_evid, v_datefrom),zsfi_GetBalanceAtTime(v_org, v_acctsh, v_evid, v_datefrom),
               0,0);
    end if;
    if v_id is not null then
        -- Kontotyp bestimmen
        SELECT TRIM(accounttype) INTO v_accounttype FROM c_elementvalue WHERE c_elementvalue_id=v_evid AND accounttype in ('A','L','O', 'E', 'R');
        if v_accounttype in ('A', 'E') then
            v_negative:='H';
        else
            v_negative:='S';
        end if;
        
        if coalesce(v_cur.i_03,'')!='' then --- Mit EB Wert
            v_saldo:= to_number(v_cur.i_03)* (case when coalesce(v_cur.i_04,'')=v_negative then -1 else 1 end);
        else -- Ohne EB Wert
            select beginningbalance into v_ozsaldo from zsfi_susadatevaccounts where zsfi_susadatevaccounts_id=v_id;
            v_saldo:=0;
            update zsfi_susadatevaccounts set beginningbalance=0,endingbalance=endingbalance-v_ozsaldo where zsfi_susadatevaccounts_id=v_id;
        end if;
        update zsfi_susadatevaccounts set 
               beginningbalancedatev=v_saldo,
               endingbalancedatev=to_number(v_cur.i_06) * (case when coalesce(v_cur.i_07,'')=v_negative then -1 else 1 end),
               debitdatev=to_number(v_cur.i_12),
               creditdatev=to_number(v_cur.i_11)
        where zsfi_susadatevaccounts_id=v_id;
        update zsfi_susadatevaccounts set difference=abs(endingbalancedatev-endingbalance) , 
               rowcolor=case when abs(endingbalancedatev-endingbalance)>0 then '#FF0000' else null end,
               updatedby=p_user,updated=now(),
               isdifference=case when (endingbalancedatev-endingbalance)!=0 then 'Y' else 'N' end
        where zsfi_susadatevaccounts_id=v_id and endingbalancedatev is not null;
    else
        v_message :=v_message ||'Konto n. vorh.:'||v_cur.i_01;
    end if;
  END LOOP;
  SELECT COUNT(*) INTO v_anzLines FROM I_SuSa;
  IF (v_anzLines > 0) THEN
    
    v_message := 'SUCCESS - '||v_anzLines || ' Datensätze importiert';
    RAISE NOTICE '%', v_message;
  ELSE
    v_message := '@ERROR=' || 'Information der Import-Datei konnte nicht ermittelt werden.';
    RAISE NOTICE '%', v_message;
    RETURN v_message;
  END IF;
  
  
  
  RAISE NOTICE '%', v_message;

  RETURN v_message;

  EXCEPTION
  WHEN OTHERS THEN
    v_message := '@ERROR=' || SQLERRM;
    RAISE NOTICE '%', v_message;
    RETURN v_message;
END;
$body_$
LANGUAGE 'plpgsql';
