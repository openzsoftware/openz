package org.openbravo.zsoft.smartui;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.database.ConnectionProvider;

public class Smartprefs {
  private static Logger log4j = Logger.getLogger(Smartprefs.class);

  public String getSmartprefs(ConnectionProvider conn, VariablesSecureApp vars, String columnname,
      String window) {

    final String selectlist = "select c_doctype_id as C_DocTypeTarget_ID,c_bpartner_id,c_bpartner_location_id,c_paymentterm_id,invoicerule,deliveryrule,m_warehouse_id, m_pricelist_id, paymentrule, deliveryviarule, freightcostrule, m_shipper_id, c_incoterms_id, weight_uom";
    final String currentOrg = vars.getOrg();
    final String currentClient = vars.getClient();
    String sql;
   // Similar Name, but not in Prefs...
   if (columnname.equalsIgnoreCase("pricelist"))
     return "";   
   // Direct Purchase
    if (window.equals("FF1F6A9FFC16491896AD11FABA646DEE")) {
      log4j.debug("In SmartInvoiceprefs. SalesInvoice Field: " + columnname);
      sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='PO' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
        return getPrefs(sql, conn, columnname);
    }
    // SmartInvoice or Sales Invoice
    if (window.equals("1BA269F3E27141F1A13895947C93D18D") || window.equals("167")) {
      log4j.debug("In SmartInvoiceprefs. SalesInvoice Field: " + columnname);
      sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='CI' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
        return getPrefs(sql, conn, columnname);
    }
    if (window.equals("183")) {
      log4j.debug("In SmartInvoiceprefs. PurchaseInvoice Field: " + columnname);
      sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='SI' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
        return getPrefs(sql, conn, columnname);
    }
    if (window.equals("143")) {
      log4j.debug("In SmartInvoiceprefs. SalesOrder Field: " + columnname);
      sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='SOW' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
        return getPrefs(sql, conn, columnname);
    }
    if (window.equals("181")) {
      log4j.debug("In SmartInvoiceprefs. Purchase Order Field: " + columnname);
      sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='POO' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
        return getPrefs(sql, conn, columnname);
    }
    if (window.equals("169")) {
      log4j.debug("In SmartInvoiceprefs. Goods Shipment Field: " + columnname);
      sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='NSH' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
        return getPrefs(sql, conn, columnname);
    }
    if (window.equals("184")) {
      log4j.debug("In SmartInvoiceprefs. Goods Receipt Field: " + columnname);
      sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='NRE' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
        return getPrefs(sql, conn, columnname);
    }
    if (window.equals("C20056F1A1954367981E9CBE26AAB675")) {
	    log4j.debug("In SmartInvoiceprefs. Offer Field: " + columnname);
	    sql = selectlist + " from zssi_smartinvoiceprefs " + " where ad_client_id = '"
	        + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
	        + " and invoicetype ='NON' order by ad_org_id desc LIMIT 1";
	    if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1 && ! columnname.equalsIgnoreCase("c_doctype_id"))
	      return getPrefs(sql, conn, columnname);
	  }
    if (window.equals("93C7676AA2A94769B48A4B6E102FDD67")) {
      log4j.debug("In SmartInvoiceprefs. Order Template, Field: " + columnname);
      sql = selectlist + ",c_doctype_id from zssi_smartinvoiceprefs " + " where ad_client_id = '"
          + currentClient + "'" + " and ad_org_id in ('0','" + currentOrg + "')" + " and isactive = 'Y'"
          + " and invoicetype ='ORDERTEMPLATE' order by ad_org_id desc LIMIT 1";
      if (selectlist.toUpperCase().indexOf(columnname.toUpperCase()) != -1)
        return getPrefs(sql, conn, columnname);
    }
    return "";
  }

  private String getPrefs(String sql, ConnectionProvider conn, String columnname) {
    try {
      Connection dbcon = conn.getConnection();
      try {
        Statement stmt = dbcon.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
            ResultSet.CONCUR_READ_ONLY);
        ResultSet srs = stmt.executeQuery(sql);
        String retval = "";
        if (srs.first())
          retval = srs.getString(columnname.toLowerCase());
        dbcon.close();
        if (retval==null)
          retval = "";
        return retval;
      } catch (final Exception e) {
        log4j.error("Smartprefs - Error: " + e);
        dbcon.close();
        return "";
      }
    } catch (final Exception e) {
      log4j.error("Smartprefs - Conn Error: " + e);
      return "";
    }
  }
}
