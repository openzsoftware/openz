package org.openz.controller.businessprocess;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

/**
 * @see Alerts: Servlet only for Use in Alerts.
 * Approves Payment and moves Back to Alert
 */
public class ApprovePOInvoicePayment extends HttpSecureAppServlet {
  
  private static final long serialVersionUID = 1L;
  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
  ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    String alert=vars.getRequestGlobalVariable("inpAlertRule","AlertManagement|AlertRule");
    String payment=vars.getStringParameter("inpcDebtPaymentId");
    String retval=BprocessCommonData.approveDebtPayment(this, vars.getUser(), payment);
    if (retval.equals("1"))
      BprocessCommonData.updateAlertrule(this, alert);

    response.sendRedirect(strDireccion + "/ad_forms/AlertManagement.html"); 
  }
}
