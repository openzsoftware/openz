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

public class DirectSalesCO extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }
 
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strProductID = vars.getStringParameter("inpmProductId"); 
      String strChanged = vars.getStringParameter("inpLastFieldChanged");

      // New Callout Structure
      CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
      
      try {
        String strUomID = CalloutData.getUomIdOfProduct(this, strProductID);
        String strPrice = CalloutData.getPriceOfProduct(this, strProductID);
        if (strChanged.equals("inpmProductId")&& ! strUomID.equals("")){
          callout.appendComboTable("inpcUomId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "C_UOM_ID",null,null,"",false), strUomID);
          callout.appendNumeric("inppriceactual", strPrice);
        }
        
     
           // callout.appendMessage("NoLocationNoTaxCalculated", this, vars);

        
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
