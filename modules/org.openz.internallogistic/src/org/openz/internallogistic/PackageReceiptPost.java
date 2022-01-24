package org.openz.internallogistic;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.scheduling.ProcessBundle;
import org.openz.pdc.PdcMainDialogue;
import org.openz.pdc.controller.SerialAndBatchNumbers;

public class PackageReceiptPost extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
ServletException {
            VariablesSecureApp vars = new VariablesSecureApp(request);
            vars.setSessionValue("PDCSTATUS","OK");
            vars.setSessionValue("PDCSTATUSTEXT",Utility.messageBD(this, "pdc_ScanIdentifier",vars.getLanguage())+"\r\n");
            vars.setSessionValue("issotrx", "Y");
            vars.setSessionValue("pdcUserID", vars.getUser());
            vars.setSessionValue("62314289EB0A4FFBA4ACDB985018C68B|Receipt62314289EB0A4FFBA4ACDB985018C68B.view","EDIT");
            vars.setSessionValue("PDCFORMERDIALOGUE","/org.openz.internallogistic.PackageReceipt/Receipt62314289EB0A4FFBA4ACDB985018C68B_Edition.html");
            String strInoutId=vars.getStringParameter("inpmInoutId");
            if (strInoutId.equals(""))
              strInoutId=vars.getSessionValue(vars.getStringParameter("inpwindowId") + "|ILS_Inoutpackage_V_ID");
                  //InternalLogisticData.getInOutIDfromDocNo(this, vars.getStringParameter("inpdocumentno"));
            vars.setSessionValue("pdcInOutID",strInoutId);
            vars.removeSessionValue("pdcConsumptionID");
            //vars.setSessionValue(SerialAndBatchNumbers.class.getName() + "|serialServletState","ORDEREDSERIAL");
            //vars.setSessionValue(SerialAndBatchNumbers.class.getName() + "|serialServletState","PSERIAL");
            vars.setSessionValue(SerialAndBatchNumbers.class.getName() + "|minternalconsumptionlineid",vars.getStringParameter("inpilsInoutpackageVId"));
            response.sendRedirect(strDireccion + "/org.openz.pdc.ad_forms/SerialAndBatchNumbers.html");                      

           //send redirect 
                 
  }
  public void execute(ProcessBundle bundle) throws Exception {

          
  }


}
