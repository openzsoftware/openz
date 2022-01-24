package org.openz.customerassets;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openz.controller.callouts.CalloutStructure;
import org.openz.util.FormatUtils;
import org.openz.view.SelectBoxhelper;

public class OrderassetstockedCO extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      String strCustomerAssetID = vars.getStringParameter("inpauxfield1"); 
      String strChanged = vars.getStringParameter("inpLastFieldChanged");
      String strOrder= vars.getStringParameter("inpcOrderId");
      String strPartner= vars.getStringParameter("inpcBpartnerId");
      String strQtyOrdered = vars.getNumericParameter("inpqtyordered");

      // New Callout Structure
      CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
      
      try {
        if (strChanged.equals("inpauxfield1")){
          String strProductID = CustomerassetsData.getProduct(this, strCustomerAssetID);  
          String strQty = CustomerassetsData.getQty(this, strProductID,strPartner);
          String strUOM = CustomerassetsData.getUOM(this, strProductID);
          String strPrice = CustomerassetsData.getPrice(this, strPartner, strProductID, strQty, strOrder);
          if (strProductID !=null && strQty!=null) {
            callout.appendComboTable("inpmProductId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "M_Product_ID",null,null,"",true), strProductID );
            callout.appendNumeric("inpqtyordered", strQty);
            callout.appendComboTable("inpcUomId", SelectBoxhelper.getReferenceDataByRefName(this, vars, "C_UOM_ID",null,null,"",true),strUOM);
            callout.appendNumeric("inppriceactual",strPrice);
            callout.appendNumeric("inppricestd",strPrice);
          }
        }
        if (strChanged.equals("inpqtyordered")){
          String strProductID = CustomerassetsData.getProduct(this, strCustomerAssetID);  
          String strQty = CustomerassetsData.getQty(this, strProductID,strPartner);
          
          if ( strQty!=null) {
            if (new BigDecimal(strQty).compareTo(new BigDecimal(strQtyOrdered))==-1)
              callout.appendNumeric("inpqtyordered", strQty);
            
          }
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
