package org.openbravo.erpCommon.utility.reporting.printing;

import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.reporting.DocumentType;

public class PrintPurchaseSubTab extends PrintController {
	  private static Logger log4j = Logger.getLogger(PrintProductionOrders.class);

	  

	  public void init(ServletConfig config) {
	    super.init(config);
	    boolHist = false;
	  }

	  @SuppressWarnings("unchecked")
	  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
	      ServletException {
	    VariablesSecureApp vars = new VariablesSecureApp(request);

	    DocumentType documentType = new DocumentType("PURCHASESUBTAB","M_PRODUCT_PO","purchasesubtab/","Purchasesubtab",true,null,"c_getDefaultDocInfo");
	    // The prefix PRINTORDERS is a fixed name based on the KEY of the
	    // AD_PROCESS
	    String sessionValuePrefix = "PRINTPURCHASESUBTAB";
	    String strDocumentId = null;

	    strDocumentId = vars.getSessionValue(sessionValuePrefix + ".inpmProductPoId_R");
	    if (strDocumentId.equals(""))
	      strDocumentId = vars.getSessionValue(sessionValuePrefix + ".inpmProductPoId");

	    post(request, response, vars, documentType, sessionValuePrefix, strDocumentId,null);
	  }

	  public String getServletInfo() {
	    return "Servlet that processes the print action";
	  } // End of getServletInfo() method
	}