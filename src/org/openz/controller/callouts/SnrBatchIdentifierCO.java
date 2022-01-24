package org.openz.controller.callouts;
import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;


import org.openz.view.SelectBoxhelper;

public class SnrBatchIdentifierCO extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strBatchID = vars.getStringParameter("inpsnrBatchmasterdataId"); 
      String strChanged = vars.getStringParameter("inpLastFieldChanged");

      // New Callout Structure
      CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
      
      try {
        String strProductId = CalloutData.getProductfromBatch(this, strBatchID);  
        String BatchIdent=CalloutData.getIdentifierOfBatch(this, strBatchID);
        String ProductIdent=CalloutData.getIdentifierOfProduct(this, strProductId);
        String MasterBatch=CalloutData.getBatchID(this, strBatchID);
        String LocatorID=CalloutData.getBatchLocatorID(this, strBatchID);
        //String BatchQty=CalloutData.getBatchQty(this,  strBatchID,MasterBatch);
        String LocatorName=CalloutData.getBatchLocatorValue(this, LocatorID);
        if (strChanged.equals("inpsnrBatchmasterdataId")){
          callout.appendString("inpmProductId_DES", ProductIdent);
          callout.appendString("inpmProductId", strProductId);
          callout.appendString("inpreceivingLocator", LocatorID);
          callout.appendString("inpreceivingLocator_DES", LocatorName);
          //callout.appendString("inpquantity", BatchQty);
          callout.appendString("inpsnrBatchmasterdataId_DES",BatchIdent);
        }
        if (strChanged.equals("inpsnrBatchmasterdataId")&&(strBatchID.isEmpty())){
          //callout.appendString("inpmProductId_DES", "");
          //callout.appendString("inpmProductId", "");
          callout.appendString("inpsnrBatchmasterdataId", "");
          callout.appendString("inpsnrBatchmasterdataId_DES", "");
        }
        
     
          

        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println(callout.returnCalloutAppFrame());
        out.close();
      } catch (Exception ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }





}
