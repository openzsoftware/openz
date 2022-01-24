package org.openbravo.erpCommon.utility.reporting.printing;


import java.io.IOException;
import java.util.Calendar;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.reporting.DocumentType;

@SuppressWarnings("serial")
public class PrintBusinessPartner  extends PrintController {
  private static Logger log4j = Logger.getLogger(PrintEmployees.class);

  // TODO: Als een email in draft staat de velden voor de email adressen
  // weghalen en melden dat het document
  // niet ge-emailed kan worden

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  @SuppressWarnings("unchecked")

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);

    DocumentType documentType = new DocumentType("BPARTNER","C_BPARTNER","bpartner/","BusinessPartner",true,"PrintOptionsBpartner","c_getDefaultDocInfo");
    // The prefix PRINTINVOICES is a fixed name based on the KEY of the
    // AD_PROCESS
    String sessionValuePrefix = "PRINTBPARTNER";
    String strDocumentId = null;

    strDocumentId = vars.getSessionValue(sessionValuePrefix + ".inpcBpartnerId_R");
    if (strDocumentId.equals(""))
      strDocumentId = vars.getSessionValue(sessionValuePrefix + ".inpcBpartnerId");
    
    post(request, response, vars, documentType, sessionValuePrefix, strDocumentId,null);
  }

  public String getServletInfo() {
    return "Servlet that processes the print action";
  } // End of getServletInfo() method
}