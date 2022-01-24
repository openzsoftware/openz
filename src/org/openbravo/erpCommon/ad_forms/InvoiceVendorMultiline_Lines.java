/*
 *************************************************************************
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
 ************************************************************************
 */

package org.openbravo.erpCommon.ad_forms;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.Tax;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;

public class InvoiceVendorMultiline_Lines extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  private static final String formClassName = "org.openbravo.erpCommon.ad_forms.InvoiceVendorMultiline";

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    String windowId = "";

    {
      InvoiceVendorMultilineData[] data = InvoiceVendorMultilineData.selectWindowData(this, vars
          .getLanguage(), formClassName);
      if (data == null || data.length == 0) {
        throw new ServletException(formClassName + ": Error on window data");
      }
      windowId = data[0].adWindowId;
    }

    if (vars.commandIn("DEFAULT")) {
      String strInvoice = vars.getStringParameter("inpcInvoiceId");
      printPageDataSheet(response, vars, strInvoice, windowId);
    } else if (vars.commandIn("HIDDEN", "SAVE_EDIT", "SAVE_NEW", "DELETE")) {
      printPageHidden(response, vars, windowId);
    } else if (vars.commandIn("PRODUCT_CALLOUT")) {
      printPageCallOut(response, vars, windowId);
    } else
      pageError(response);
  }

  private void printPageCallOut(HttpServletResponse response, VariablesSecureApp vars,
      String windowId) throws IOException, ServletException {
    response.setContentType("text/plain");
    response.setHeader("Cache-Control", "no-cache");
    PrintWriter out = response.getWriter();
    String strMProductID = vars.getStringParameter("inpmProductId");
    String strcInvoiceId = vars.getStringParameter("inpcInvoiceId");
    String strWarehouse = Utility.getContext(this, vars, "#M_Warehouse_ID", windowId);
    String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
    InvoiceVendorMultilineData[] data = InvoiceVendorMultilineData.select(this, strDateFormat, vars
        .getLanguage(), strcInvoiceId);
    if (data != null && data.length > 0) {
      out.print(Tax.get(this, strMProductID, data[0].dateinvoiced, data[0].adOrgId, strWarehouse,
          data[0].cBpartnerLocationId, data[0].cBpartnerLocationId, data[0].cProjectId,
          data[0].issotrx.equals("Y")));
    } else {
      out.print("");
    }
    out.close();
  }

  private void printPageDataSheet(HttpServletResponse response, VariablesSecureApp vars,
      String strInvoice, String windowId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: dataSheet");
    InvoiceVendorMultilineLinesData[] data = InvoiceVendorMultilineLinesData.select(this, vars
        .getLanguage(), strInvoice);
    if (!strInvoice.equals("") && (data == null || data.length == 0))
      data = InvoiceVendorMultilineLinesData.set(InvoiceVendorMultilineLinesData.selectNextLine(
          this, strInvoice));

    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_forms/InvoiceVendorMultiline_Lines").createXmlDocument();

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("cInvoiceId", strInvoice);
    String strTax = "";
    if (data != null && data.length > 0)
      strTax = data[0].cTaxId;

    try {
      ComboTableData comboTableData = new ComboTableData(vars, this, "TABLE", "C_Tax_ID", "C_Tax",
          "", Utility.getContext(this, vars, "#AccessibleOrgTree", windowId), Utility.getContext(
              this, vars, "#User_Client", windowId), 0);
      Utility.fillSQLParameters(this, vars, null, comboTableData, windowId, strTax);
      xmlDocument.setData("reportC_Tax_ID", "liststructure", comboTableData.select(false));
      comboTableData = null;
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setData("structure1", data);

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private InvoiceVendorMultilineLinesData getEditVariables(VariablesSecureApp vars, String windowId)
      throws IOException, ServletException {
    InvoiceVendorMultilineLinesData data = new InvoiceVendorMultilineLinesData();

    data.cInvoicelineId = vars.getStringParameter("inpcInvoicelineId");
    data.cInvoiceId = vars.getRequestGlobalVariable("inpcInvoiceId", windowId + "|C_Invoice_ID");
    data.adClientId = vars.getGlobalVariable("inpadClientId", windowId + "|AD_Client_ID", vars
        .getClient());
    data.adOrgId = vars.getGlobalVariable("inpadOrgId", windowId + "|AD_Org_ID", vars.getOrg());
    data.isactive = vars.getStringParameter("inpisactive", "Y");
    data.cOrderlineId = vars.getStringParameter("inpcOrderlineId");
    data.mInoutlineId = vars.getStringParameter("inpmInoutlineId");
    data.line = vars.getStringParameter("inpline");
    data.description = vars.getStringParameter("inpdescription");
    data.mProductId = vars.getStringParameter("inpmProductId" + data.cInvoicelineId);
    data.qtyinvoiced = vars.getNumericParameter("inpqtyinvoiced");
    data.pricelist = vars.getNumericParameter("inppricelist", "1");
    data.priceactual = vars.getNumericParameter("inppriceactual", "1");
    data.pricelimit = vars.getNumericParameter("inppricelimit", "1");
    data.pricestd = vars.getNumericParameter("inppricestd", "1");
    data.cChargeId = vars.getStringParameter("inpcChargeId");
    data.chargeamt = vars.getNumericParameter("inpchargeamt", "0");
    data.cUomId = vars.getStringParameter("inpcUomId");
    data.cTaxId = vars.getStringParameter("inpcTaxId");
    data.sResourceassignmentId = vars.getStringParameter("inpsResourceassignmentId");
    data.taxamt = vars.getNumericParameter("inptaxamt", "0");
    data.mAttributesetinstanceId = vars.getStringParameter("inpmAttributesetinstanceId");
    data.isdescription = vars.getStringParameter("inpisdescription", "N");
    data.quantityorder = vars.getNumericParameter("inpquantityorder");
    data.mProductUomId = vars.getStringParameter("inpmProductUomId");
    data.cInvoiceDiscountId = vars.getStringParameter("inpcInvoiceDiscountId");

    data.createdby = vars.getUser();
    data.updatedby = vars.getUser();

    if (data.cUomId.equals("") && !data.mProductId.equals(""))
      data.cUomId = InvoiceVendorMultilineLinesData.selectUOM(this, data.mProductId);

    if (log4j.isDebugEnabled())
      log4j.debug("C_InvoiceLine_ID: " + data.cInvoicelineId);
    if (log4j.isDebugEnabled())
      log4j.debug("C_Invoice_ID: " + data.cInvoiceId);
    if (log4j.isDebugEnabled())
      log4j.debug("AD_Client_ID: " + data.adClientId);
    if (log4j.isDebugEnabled())
      log4j.debug("AD_Org_ID: " + data.adOrgId);
    if (log4j.isDebugEnabled())
      log4j.debug("IsActive: " + data.isactive);
    if (log4j.isDebugEnabled())
      log4j.debug("C_OrderLine_ID: " + data.cOrderlineId);
    if (log4j.isDebugEnabled())
      log4j.debug("M_InoutLine_ID: " + data.mInoutlineId);
    if (log4j.isDebugEnabled())
      log4j.debug("Line: " + data.line);
    if (log4j.isDebugEnabled())
      log4j.debug("Description: " + data.description);
    if (log4j.isDebugEnabled())
      log4j.debug("M_Product_ID: " + data.mProductId);
    if (log4j.isDebugEnabled())
      log4j.debug("QtyInvoiced: " + data.qtyinvoiced);
    if (log4j.isDebugEnabled())
      log4j.debug("PriceList: " + data.pricelist);
    if (log4j.isDebugEnabled())
      log4j.debug("PriceActual: " + data.priceactual);
    if (log4j.isDebugEnabled())
      log4j.debug("PriceLimit: " + data.pricelimit);
    if (log4j.isDebugEnabled())
      log4j.debug("C_Charge_ID: " + data.cChargeId);
    if (log4j.isDebugEnabled())
      log4j.debug("ChargeAmt: " + data.chargeamt);
    if (log4j.isDebugEnabled())
      log4j.debug("C_UOM_ID: " + data.cUomId);
    if (log4j.isDebugEnabled())
      log4j.debug("C_Tax_ID: " + data.cTaxId);
    if (log4j.isDebugEnabled())
      log4j.debug("S_ResourceAssignment_ID: " + data.sResourceassignmentId);
    if (log4j.isDebugEnabled())
      log4j.debug("TaxAmt: " + data.taxamt);
    if (log4j.isDebugEnabled())
      log4j.debug("M_AttributeSetInstance_ID: " + data.mAttributesetinstanceId);
    if (log4j.isDebugEnabled())
      log4j.debug("IsDescription: " + data.isdescription);
    if (log4j.isDebugEnabled())
      log4j.debug("QuantityOrder: " + data.quantityorder);
    if (log4j.isDebugEnabled())
      log4j.debug("M_Product_UOM_ID: " + data.mProductUomId);
    if (log4j.isDebugEnabled())
      log4j.debug("C_Invoice_Discount_ID: " + data.cInvoiceDiscountId);

    return data;
  }

  private void printPageHidden(HttpServletResponse response, VariablesSecureApp vars,
      String windowId) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: hidden");
    InvoiceVendorMultilineLinesData data = getEditVariables(vars, windowId);
    String strIDNew = "";
    String strMensaje = "";
    String strLineNo = "";

    try {
      if (vars.commandIn("DELETE")) {
        if (data.cInvoicelineId.equals(""))
          strMensaje = Utility.messageBD(this, "ProcessError", vars.getLanguage());
        else {
          Connection conn = getTransactionConnection();
          try {
            if (data.delete(conn, this) == 0)
              strMensaje = Utility.messageBD(this, "ProcessError", vars.getLanguage());
            releaseCommitConnection(conn);
          } catch (Exception ex1) {
            try {
              releaseRollbackConnection(conn);
            } catch (Exception ignored) {
            }
            ex1.printStackTrace();
            log4j.error("Failed delete on expense Invoice lines - ROLLBACK");
            strMensaje = Utility.messageBD(this, "ProcessError", vars.getLanguage());
          }
        }
      } else if (vars.commandIn("SAVE_NEW", "SAVE_EDIT")) {
        if (data.cInvoicelineId.equals("")) {
          strIDNew = SequenceIdData.getUUID();
          data.cInvoicelineId = strIDNew;
          if (data.insert(this) == 0)
            strMensaje = Utility.messageBD(this, "ProcessError", vars.getLanguage());
          strLineNo = InvoiceVendorMultilineLinesData.selectLineNo(this, strIDNew);
          data.cInvoicelineId = "";
        } else {
          if (data.update(this) == 0)
            strMensaje = Utility.messageBD(this, "ProcessError", vars.getLanguage());
          strLineNo = InvoiceVendorMultilineLinesData.selectLineNo(this, data.cInvoicelineId);
        }
      }
    } catch (Exception ex) {
      strMensaje = ex.getMessage();
    }
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/utility/FrameOcultoMultilinea").createXmlDocument();
    StringBuffer datos = new StringBuffer();
    datos.append("var respuesta = new Array(\n");
    if (!vars.commandIn("HIDDEN")) {
      if (!strMensaje.equals("")) {
        datos.append("new Array(\"Command\", \"ERROR\"),\n");
        datos.append("new Array(\"inpcInvoicelineId\", \"").append(data.cInvoicelineId).append(
            "\"),\n");
        datos.append("new Array(\"MENSAJE_ERROR\", \"").append(
            Utility.messageBD(this, strMensaje, vars.getLanguage())).append("\"),\n");
      } else {
        datos.append("new Array(\"Command\", \"").append(vars.getCommand()).append("\"),\n");
        datos.append("new Array(\"inpcInvoicelineId\", \"").append(data.cInvoicelineId).append(
            "\"),\n");
        datos.append("new Array(\"inpmProductId\", \"").append(data.mProductId).append("\"),\n");
        datos.append("new Array(\"inplineno\", \"").append(strLineNo).append("\"),\n");
        datos.append("new Array(\"inppriceactual\", \"").append(data.priceactual).append("\"),\n");
        datos.append("new Array(\"inpqtyinvoiced\", \"").append(data.qtyinvoiced).append("\"),\n");
        datos.append("new Array(\"inpcTaxId\", \"").append(data.cTaxId).append("\"),\n");
        datos.append("new Array(\"inpcInvoicelineIdNew\", \"").append(
            data.cInvoicelineId.equals("") ? strIDNew : data.cInvoicelineId).append("\"),\n");
      }
      datos.append("new Array(\"Formulario\", \"document.frmMain\")");
    }
    datos.append(");\n");
    datos.append("var respuestaNew = new Array(\n");
    if (strMensaje.equals("") && vars.commandIn("SAVE_NEW", "DELETE")) {
      datos.append("new Array(\"LineNo\", \"").append(
          InvoiceVendorMultilineLinesData.selectNextLine(this, data.cInvoiceId)).append("\")\n");
      FieldProvider[] fp = null;
      try {
        ComboTableData comboTableData = new ComboTableData(vars, this, "TABLE", "", "C_Tax", "",
            Utility.getContext(this, vars, "#AccessibleOrgTree", windowId), Utility.getContext(
                this, vars, "#User_Client", windowId), 0);
        Utility.fillSQLParameters(this, vars, null, comboTableData, windowId, "");
        fp = comboTableData.select(false);
        comboTableData = null;
      } catch (Exception ex) {
        throw new ServletException(ex);
      }

      if (fp != null && fp.length > 0) {
        datos.append(", new Array(\"inpcTaxId\", new Array(\n");
        for (int i = 0; i < fp.length; i++) {
          datos.append("new Array(\"").append(fp[i].getField("id")).append("\", \"").append(
              fp[i].getField("name")).append("\")\n");
          if (i < fp.length - 1)
            datos.append(", ");
        }
        datos.append(")\n");
        datos.append(")\n");
      }
    }
    datos.append(");\n");
    xmlDocument.setParameter("array", datos.toString());
    xmlDocument.setParameter("targetFrame", vars.getStringParameter("target"));

    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  public String getServletInfo() {
    return "InvoiceVendorMultiline_Lines Servlet";
  } // end of getServletInfo() method
}
