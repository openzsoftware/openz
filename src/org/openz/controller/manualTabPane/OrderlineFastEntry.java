package org.openz.controller.manualTabPane;


/*****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
import java.sql.Connection;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletResponse;

import org.openz.view.*;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openz.view.templates.*;
import org.openbravo.utils.Replace;
import org.openbravo.erpCommon.ad_callouts.ProductTextHelper;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;

public class OrderlineFastEntry extends ProductTextHelper implements ManualTabPane {


  private static final long serialVersionUID = 1L;

  public String getFormEdit(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,WindowTabs tabs,HttpServletResponse response,ToolBar stdtoolbar) throws Exception{
    String toolbarid=FormhelperData.getTabEditionToolbar(servlet,servlet.getClass().getName());
    Connection conn = null;
    Scripthelper script = new Scripthelper();
    OrderlineFastEntryData[] GridData;
    String strOrderid=vars.getSessionValue(vars.getStringParameter("inpwindowId") + "|c_order_id");
    String strOrgid=vars.getSessionValue(vars.getStringParameter("inpwindowId") + "|ad_org_id");
    script.addHiddenfield("inpadOrgId", strOrgid);
    String strCommand=vars.getStringParameter("inpCommandType");
    servlet.setCommandtype("");
    EditableGrid grid = new EditableGrid("OrderFastEntryGrid", vars, servlet);  
    String msg="";
    String msgType="SUCCESS";
    String msgHeader="Success";
    String strpvaluefilter="%";
    String strpnamefilter="%";
    try {
      // SAVE-ACTION
      if (strCommand.equals("SAVE")|| strCommand.equals("SAVEANDHEAD")) {
        Vector <String> retval;
        conn= servlet.getTransactionConnection();
        retval=grid.getSelectedIds(servlet, vars, "c_orderline_id");
        String strOrderlineId,strLine,strProduct,strQty,strDescription,strPrice,strAux;
        for (int i = 0; i < retval.size(); i++) {
          strOrderlineId=retval.elementAt(i);
          strLine=grid.getValue(servlet, vars, strOrderlineId, "Line");
          strProduct=grid.getValue(servlet, vars, strOrderlineId, "M_Product_ID");
          strQty=grid.getValue(servlet, vars, strOrderlineId, "qtyordered");
          strAux=grid.getValue(servlet, vars, strOrderlineId, "auxfield1");
          strDescription=grid.getValue(servlet, vars, strOrderlineId, "description");
          //OrderlineFastEntryData.getOffersPrice(servlet, strProduct, strQty, strOrderid);
          String priceoffer=grid.getValue(servlet, vars, strOrderlineId, "priceactual");
          //Calc and set..
          String pricelist=OrderlineFastEntryData.getListPrice(servlet, strProduct, strOrderid);
          String pricestd=OrderlineFastEntryData.getStdPrice(servlet, strProduct, strOrderid);
          String discount=OrderlineFastEntryData.getDiscount(servlet, pricestd, priceoffer, strOrderid);
          // INsert or Update?
          if (OrderlineFastEntryData.isExisting(servlet,  strOrderlineId).equals("0")) 
            OrderlineFastEntryData.insert(conn, servlet, strOrderid,strProduct, strQty,priceoffer, pricelist,pricestd,discount,"");          

          
          OrderlineFastEntryData.update(conn, servlet,strProduct,strQty,strDescription,vars.getUser(), pricelist,priceoffer,discount,strAux,strOrderlineId);
          if (msg.isEmpty())
            msg=Utility.messageBD(servlet, "OrderlineUpdatedSucessfully",vars.getLanguage());
        }   
        servlet.releaseCommitConnection(conn);
      }  
      // PICKLIST-ACTION
      if (strCommand.equals("PICKLIST")) {
        Vector <String> retval;
        conn= servlet.getTransactionConnection();
        retval=vars.getListFromInString(vars.getInStringParameter("inpproductlist"));
        String strOrderlineId,strLine,strProduct,strQty;
        strLine=OrderlineFastEntryData.gfetNextLine(servlet, strOrderid);
        for (int i = 0; i < retval.size(); i++) {
          strProduct=retval.elementAt(i);
          strQty="1";
          String strPositionText = this.getDocumentText(strProduct, "", "Y", strOrgid,vars.getLanguage(),null,null,servlet);
          strPositionText=strPositionText.replace("\\n", "\r");
          //Calc and set..
          String pricelist=OrderlineFastEntryData.getListPrice(servlet, strProduct, strOrderid);
          String pricestd=OrderlineFastEntryData.getStdPrice(servlet, strProduct, strOrderid);
          String priceoffer=OrderlineFastEntryData.getOffersPrice(servlet, strProduct, strQty, strOrderid);
          String discount=OrderlineFastEntryData.getDiscount(servlet, pricestd, priceoffer, strOrderid);
          strOrderlineId=OrderlineFastEntryData.insert(conn, servlet, strOrderid,strProduct, strQty,priceoffer, pricelist,pricestd,discount,strPositionText);          
          //OrderlineFastEntryData.update(conn, servlet,strProduct,strQty,strPositionText,vars.getUser(),pricelist,priceoffer,discount,strOrderlineId);
          strLine=Integer.toString(Integer.parseInt(strLine)+10);
          if (msg.isEmpty())
            msg=Utility.messageBD(servlet, "OrderlineCreatedSucessfully",vars.getLanguage());
        }   
        servlet.releaseCommitConnection(conn);
        }
      if (strCommand.equals("DELETE")) {
        String strPTBOMId;
        Vector <String> retval;
        conn= servlet.getTransactionConnection();
        retval=grid.getSelectedIds(null, vars, "c_orderline_id");
        for (int i = 0; i < retval.size(); i++) {
          strPTBOMId=retval.elementAt(i);
          OrderlineFastEntryData.delete(conn, servlet, strPTBOMId);
          msg=Utility.messageBD(servlet, "OrderlineDeletedSucessfully",vars.getLanguage());
        }
        servlet.releaseCommitConnection(conn);
      }
      if (strCommand.equals("FILTER")) {
       
      }
      
    } catch (final ServletException ex) {
        final OBError myError = Utility.translateError(servlet, vars, vars.getLanguage(), ex.getMessage());
        msg=myError.getMessage();
        msgHeader=myError.getTitle();
        msgType=myError.getType();   
        try {
            releaseRollbackConnection(conn);
        } catch (final Exception ignored) {
        }
    }
    // Set Message for Main Tab
    if (OrderlineFastEntryData.isFreight(servlet, strOrderid).equals("Y"))  {
      String mymsg=Utility.messageBD(servlet, "OrderNeedsFreightexpl",vars.getLanguage());
      String mymsgtit=Utility.messageBD(servlet, "OrderNeedsFreight",vars.getLanguage());
      OBError myMessage = new OBError();
      myMessage.setType("INFO");
      myMessage.setTitle(mymsgtit);
      myMessage.setMessage(mymsg);
      vars.setMessage("186", myMessage);
    }
    if (strCommand.equals("SAVEANDHEAD")) {
      response.sendRedirect(strDireccion + "/SalesOrder/Header_Edition.html");      
    }
    // Set Filter
    strpvaluefilter=vars.getRequestGlobalVariable("inpproductnumber", vars.getStringParameter("inpwindowId") + "|productnumber");
    if (strpvaluefilter.isEmpty())
      strpvaluefilter="%";
    strpnamefilter=vars.getRequestGlobalVariable("inppname", vars.getStringParameter("inpwindowId") + "|pname");
    if (strpnamefilter.isEmpty())
      strpnamefilter="%";
    // NEW-ACTION OR all OTHER Actions
    GridData=OrderlineFastEntryData.select(servlet, vars.getLanguage(),strOrderid,strpvaluefilter,strpnamefilter);
    String strLeftabsmode=FormhelperData.getLeftTabsMode4Tab(servlet,servlet.getClass().getName());
    if (!msg.equals(""))
      script.addMessage(servlet, vars, msgType, msgHeader,msg);
    String strSkeleton = ConfigureFrameWindow.doConfigureWindowMode(servlet,vars,"description",tabs.breadcrumb(), "OrderFastEntry",toolbarid,strLeftabsmode,tabs,"_Relation",null);
    Formhelper fh=new Formhelper();
    
    String strGrid = grid.printGrid(servlet, vars, script, GridData); 
    String strTableStructure=fh.prepareFieldgroup(servlet, vars, script, "OrderFastEntryFG",null,true);
    strSkeleton=Replace.replace(strSkeleton, "@CONTENT@", strTableStructure + strGrid);  
    // Add Search Shortcut
    script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('EDIT', true, null, null, '_self');\",\"inpproductnumber\",\"null\");");
    script.addOnload("keyArray[keyArray.length] = new keyArrayItem(\"ENTER\", \"submitCommandForm('EDIT', true, null, null, '_self');\",\"inppname\",\"null\");");
    script.addHiddenfieldWithID("enabledautosave", "N");
    strSkeleton = script.doScript(strSkeleton, "",servlet,vars);
    return strSkeleton;
  }
  public void setFormSave(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,Connection con){
	  
  }
}