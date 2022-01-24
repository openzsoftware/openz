SELECT zsse_DropView ('c_invoice_creditcard_v'); -- SQL-DLL 056
-- SELECT zsse_dropview('c_invoice_creditcard_line_v');
-- SELECT zsse_dropview('c_invoice_creditcard_v');

CREATE OR REPLACE VIEW c_invoice_creditcard_v AS 
 SELECT c_invoice.c_invoice_id AS c_invoice_creditcard_v_id, c_invoice.c_invoice_id, c_invoice.ad_client_id, c_invoice.ad_org_id, c_invoice.isactive, c_invoice.created, c_invoice.createdby, 
        c_invoice.updated, c_invoice.updatedby, c_invoice.issotrx, c_invoice.documentno, c_invoice.docstatus, c_invoice.docaction, c_invoice.processing, c_invoice.processed, c_invoice.posted, 
        c_invoice.c_doctype_id, c_invoice.c_doctypetarget_id, c_invoice.description, c_invoice.dateinvoiced, c_invoice.dateacct, c_invoice.c_bpartner_id, c_invoice.c_bpartner_location_id, 
        c_invoice.c_currency_id, c_invoice.paymentrule, c_invoice.c_paymentterm_id, c_invoice.totallines, c_invoice.grandtotal, c_invoice.m_pricelist_id, c_invoice.c_activity_id, c_invoice.generateto, 
        c_invoice.ad_user_id, c_invoice.ad_orgtrx_id, c_invoice.isgrossinvoice, c_invoice.transactiondate, c_invoice.internalnote
   FROM c_invoice
  WHERE 1 = 1 AND c_invoice.issotrx = 'N'::bpchar AND c_invoice.c_doctype_id::text = '3CC248B45ED8440B9CAB57337D26BA56'::text;

ALTER TABLE c_invoice_creditcard_v OWNER TO postgres;


-- Rule: c_invoice_creditcard_v_delete ON c_invoice_creditcard_v

-- DROP RULE c_invoice_creditcard_v_delete ON c_invoice_creditcard_v;

CREATE OR REPLACE RULE c_invoice_creditcard_v_delete AS
    ON DELETE TO c_invoice_creditcard_v DO INSTEAD  DELETE FROM c_invoice
  WHERE c_invoice.c_invoice_id::text = old.c_invoice_creditcard_v_id::text;

-- Rule: c_invoice_creditcard_v_insert ON c_invoice_creditcard_v

-- DROP RULE c_invoice_creditcard_v_insert ON c_invoice_creditcard_v;

CREATE OR REPLACE RULE c_invoice_creditcard_v_insert AS
    ON INSERT TO c_invoice_creditcard_v DO INSTEAD  
       INSERT INTO c_invoice (c_invoice_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, issotrx, documentno, docstatus, docaction, processing, processed, posted, 
                              c_doctype_id, c_doctypetarget_id, description, dateinvoiced, dateacct, c_bpartner_id, c_bpartner_location_id, c_currency_id, paymentrule, c_paymentterm_id, totallines, 
                              grandtotal, m_pricelist_id, c_activity_id, generateto, ad_user_id, ad_orgtrx_id, isgrossinvoice, transactiondate, internalnote) 
       VALUES (new.c_invoice_creditcard_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby, new.issotrx, new.documentno, new.docstatus, new.docaction, new.processing, new.processed, new.posted, 
               new.c_doctype_id, new.c_doctypetarget_id, new.description, new.dateinvoiced, new.dateacct, new.c_bpartner_id, new.c_bpartner_location_id, new.c_currency_id, new.paymentrule, new.c_paymentterm_id, new.totallines, 
               new.grandtotal, new.m_pricelist_id, new.c_activity_id, new.generateto, new.ad_user_id, new.ad_orgtrx_id, new.isgrossinvoice, new.transactiondate, new.internalnote);

-- Rule: c_invoice_creditcard_v_update ON c_invoice_creditcard_v

-- DROP RULE c_invoice_creditcard_v_update ON c_invoice_creditcard_v;

CREATE OR REPLACE RULE c_invoice_creditcard_v_update AS
    ON UPDATE TO c_invoice_creditcard_v DO INSTEAD  
       UPDATE c_invoice SET c_invoice_id = new.c_invoice_creditcard_v_id, ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id, isactive = new.isactive, created = new.created, 
                            createdby = new.createdby, updated = new.updated, updatedby = new.updatedby, issotrx = new.issotrx, documentno = new.documentno, docstatus = new.docstatus, 
                            docaction = new.docaction, processing = new.processing, processed = new.processed, posted = new.posted, c_doctype_id = new.c_doctype_id, 
                            c_doctypetarget_id = new.c_doctypetarget_id, description = new.description, dateinvoiced = new.dateinvoiced, dateacct = new.dateacct, c_bpartner_id = new.c_bpartner_id, 
                            c_bpartner_location_id = new.c_bpartner_location_id, c_currency_id = new.c_currency_id, paymentrule = new.paymentrule, c_paymentterm_id = new.c_paymentterm_id, 
                            totallines = new.totallines, grandtotal = new.grandtotal, m_pricelist_id = new.m_pricelist_id, c_activity_id = new.c_activity_id, generateto = new.generateto, 
                            ad_user_id = new.ad_user_id, ad_orgtrx_id = new.ad_orgtrx_id, isgrossinvoice = new.isgrossinvoice, transactiondate = new.transactiondate, internalnote = new.internalnote
  WHERE c_invoice.c_invoice_id::text = new.c_invoice_creditcard_v_id::text;





SELECT zsse_DropView ('c_invoiceline_creditcard_v');
CREATE OR REPLACE VIEW c_invoiceline_creditcard_v AS 
 SELECT c_invoiceline.c_invoiceline_id AS c_invoiceline_creditcard_v_id, c_invoiceline.c_invoiceline_id, c_invoiceline.ad_client_id, c_invoiceline.ad_org_id, c_invoiceline.isactive, 
        c_invoiceline.created, c_invoiceline.createdby, c_invoiceline.updated, c_invoiceline.updatedby, c_invoiceline.c_invoice_id, c_invoiceline.c_invoice_id AS c_invoice_creditcard_v_id,
        c_invoiceline.c_orderline_id, c_invoiceline.m_inoutline_id, c_invoiceline.line, c_invoiceline.description, c_invoiceline.m_product_id, c_invoiceline.qtyinvoiced, c_invoiceline.priceactual, 
        c_invoiceline.linenetamt, c_invoiceline.c_uom_id, c_invoiceline.c_tax_id, c_invoiceline.isgrossprice, c_invoiceline.linegrossamt, c_invoiceline.c_project_id, c_invoiceline.a_asset_id, 
        c_invoiceline.hasvoucher, c_invoiceline.voucherdate, c_invoiceline.c_cashline_id, c_invoiceline.ad_user_id
   FROM c_invoiceline, c_invoice_creditcard_v invccv
  WHERE c_invoiceline.c_invoice_id::text = invccv.c_invoice_id::text;



-- Rule: c_invoiceline_creditcard_v_insert ON c_invoiceline_creditcard_v

-- DROP RULE c_invoiceline_creditcard_v_insert ON c_invoiceline_creditcard_v;

CREATE OR REPLACE RULE c_invoiceline_creditcard_v_insert AS
    ON INSERT TO c_invoiceline_creditcard_v DO INSTEAD  
       INSERT INTO c_invoiceline (c_invoiceline_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby, c_invoice_id, c_orderline_id,
                                  m_inoutline_id, line, description, m_product_id, qtyinvoiced, priceactual, linenetamt, c_uom_id, c_tax_id, isgrossprice, linegrossamt, 
                                  c_project_id, a_asset_id, hasvoucher, voucherdate, c_cashline_id, ad_user_id) 
              VALUES (new.c_invoiceline_creditcard_v_id, new.ad_client_id, new.ad_org_id, new.isactive, new.created, new.createdby, new.updated, new.updatedby, new.c_invoice_creditcard_v_id, new.c_orderline_id,
                                  new.m_inoutline_id, new.line, new.description, new.m_product_id, new.qtyinvoiced, new.priceactual, new.linenetamt, new.c_uom_id, new.c_tax_id, new.isgrossprice, new.linegrossamt, 
                                  new.c_project_id, new.a_asset_id, new.hasvoucher, new.voucherdate, new.c_cashline_id, new.ad_user_id);

-- Rule: c_invoiceline_creditcard_v_update ON c_invoiceline_creditcard_v

-- DROP RULE c_invoiceline_creditcard_v_update ON c_invoiceline_creditcard_v;

CREATE OR REPLACE RULE c_invoiceline_creditcard_v_update AS
    ON UPDATE TO c_invoiceline_creditcard_v DO INSTEAD  
       UPDATE c_invoiceline SET c_invoiceline_id = new.c_invoiceline_creditcard_v_id, ad_client_id = new.ad_client_id, ad_org_id = new.ad_org_id, isactive = new.isactive, created = new.created, 
                                                   createdby = new.createdby, updated = new.updated, updatedby = new.updatedby, c_invoice_id = new.c_invoice_id, c_orderline_id = new.c_orderline_id,
                                                   m_inoutline_id = new.m_inoutline_id, line = new.line, description = new.description, m_product_id = new.m_product_id, qtyinvoiced = new.qtyinvoiced, 
                                                   priceactual = new.priceactual, linenetamt = new.linenetamt, c_uom_id = new.c_uom_id, c_tax_id = new.c_tax_id, isgrossprice = new.isgrossprice,
                                                   linegrossamt = new.linegrossamt, c_project_id = new.c_project_id, a_asset_id = new.a_asset_id, hasvoucher = new.hasvoucher, voucherdate = new.voucherdate,
                                                   c_cashline_id = new.c_cashline_id, ad_user_id = new.ad_user_id
       WHERE c_invoiceline.c_invoiceline_id::text = new.c_invoiceline_creditcard_v_id::text;


CREATE OR REPLACE RULE c_invoiceline_creditcard_v_delete AS
    ON DELETE TO c_invoiceline_creditcard_v DO INSTEAD  DELETE FROM c_invoiceline
  WHERE c_invoiceline.c_invoiceline_id::text = old.c_invoiceline_creditcard_v_id::text;

SELECT zsse_DropView ('c_invoice_creditcard_line_v');
CREATE OR REPLACE VIEW c_invoice_creditcard_line_v AS 
 SELECT inv_line.c_invoiceline_id AS c_invoice_creditcard_line_v_id, inv_line.c_invoiceline_id AS c_invoiceline_creditcard_v_id, inv_ccv.c_invoice_id AS c_invoice_creditcard_v_id, 
        inv_ccv.ad_client_id, inv_ccv.ad_org_id, inv_ccv.isactive, inv_ccv.created, inv_ccv.createdby, inv_ccv.updated, inv_ccv.updatedby, inv_ccv.issotrx, inv_ccv.documentno AS invoicedocumentno, 
        inv_ccv.docstatus, inv_ccv.docaction, inv_ccv.processed, inv_ccv.c_doctype_id, inv_ccv.description, inv_ccv.dateacct, inv_ccv.c_bpartner_id, inv_ccv.c_bpartner_location_id, 
        inv_ccv.c_currency_id, inv_ccv.paymentrule, inv_ccv.c_paymentterm_id, inv_ccv.totallines, inv_ccv.grandtotal, inv_ccv.m_pricelist_id, inv_ccv.ad_user_id, inv_ccv.isgrossinvoice, 
        inv_ccv.internalnote, inv_line.isactive AS lineisactive, inv_line.created AS linecreated, inv_line.createdby AS linecreatedby, inv_line.updated AS lineupdated, 
        inv_line.updatedby AS lineupdatedby, inv_line.c_orderline_id, inv_line.line, inv_line.description AS linedescription, inv_line.m_product_id, inv_line.qtyinvoiced, 
        inv_line.priceactual, inv_line.linenetamt, inv_line.c_uom_id, inv_line.c_tax_id, inv_line.linegrossamt, inv_line.c_project_id, inv_line.a_asset_id, inv_line.hasvoucher, 
        inv_line.voucherdate, inv_line.c_cashline_id, inv_line.ad_user_id AS lineaduser
   FROM c_invoice_creditcard_v inv_ccv, c_invoiceline inv_line
  WHERE inv_ccv.c_invoice_creditcard_v_id::text = inv_line.c_invoice_id::text;

ALTER TABLE c_invoice_creditcard_line_v OWNER TO tad;


