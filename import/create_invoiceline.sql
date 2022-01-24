

drop table  zsi_invoiceline;
create table zsi_invoiceline (
    datum              timestamp without time zone  not null,
    line_text          character varying(50)        not null,
    line_sum           numeric              
);

ALTER TABLE public.zsi_invoiceline OWNER TO tad;




DROP FUNCTION zsi_import();
CREATE FUNCTION  zsi_import() RETURNS character varying
AS $_$
DECLARE
i integer;
ad_org character varying:='13D5DF4C22E947F182DF177634A094D6';
ad_client character varying:='C726FEC915A54A0995C568555DA5BB3C';
creator  character varying:='DDAA21D11CB04D4D8EC59E39934B27FB';
product character varying:='C62D1C0D778D4B3193DF995283A78DA2';
tax character varying:='751E587B82E74FD18E8669D3E966D145';
uom character varying:='50473A6C17A44B70A45FCCAA522D55F1';
imps  zsi_invoiceline%rowtype;
invs c_invoice%rowtype;
mwst numeric;
netto numeric;

BEGIN 
      for invs in (select * from c_invoice where documentno like 'KB%' and ad_client_id=ad_client)
      loop
        i:=10;
        mwst:=0;
        netto:=0;
	for imps in (select *  from zsi_invoiceline where trunc(datum)=trunc(invs.dateinvoiced))
	loop
           insert into c_invoiceline(C_INVOICELINE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, C_INVOICE_ID, LINE, DESCRIPTION, M_PRODUCT_ID, QTYINVOICED, PRICELIST, PRICEACTUAL, PRICELIMIT, LINENETAMT, C_UOM_ID, C_TAX_ID, ISGROSSPRICE, LINEGROSSAMT, LINETAXAMT)
                              values(get_uuid(),       ad_client,    ad_org,    'Y',      now()  , creator, now(), creator,    invs.C_INVOICE_ID,i, imps.line_text,product,1,imps.line_sum,imps.line_sum,imps.line_sum,imps.line_sum/1.19,uom,tax,'Y',imps.line_sum,(imps.line_sum/1.19)*0.19);
           i:=i+10;
           mwst:=mwst+((imps.line_sum/1.19)*0.19);
           netto:=netto+imps.line_sum;
        end loop;
       -- insert into c_invoicetax(C_TAX_ID, C_INVOICE_ID, AD_CLIENT_ID, AD_ORG_ID, ISACTIVE, CREATED, CREATEDBY, UPDATED, UPDATEDBY, TAXBASEAMT, TAXAMT, LINE, C_INVOICETAX_ID, RECALCULATE)
       --                   values(tax,invs.C_INVOICE_ID,ad_client,    ad_org,    'Y',      now()  , creator, now(), creator,netto,mwst,10,get_uuid(),'N');

     end loop;
     RETURN 'Created...';
END;
$_$  LANGUAGE 'plpgsql';
     
alter function public.zsi_import() owner to tad;    
     





 
