package org.openbravo.erpCommon.ad_actionButton;
/****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.text.DateFormat;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.ad_actionButton.ActionButtonDefaultData;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.xmlEngine.XmlDocument;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;

public class ProposalActions  extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
  ServletException {
VariablesSecureApp vars = new VariablesSecureApp(request);

if (vars.commandIn("DEFAULT")) {
        String strProcessId = vars.getStringParameter("inpProcessId");
        String strWindow = vars.getStringParameter("inpwindowId");
        String strTab = vars.getStringParameter("inpTabId");
        String strKey = vars.getGlobalVariable("inpcOrderId", strWindow + "|C_ORDER_ID");
        
        printPage(response, vars, strKey,  strWindow, strTab, strProcessId);
       
      } else if (vars.commandIn("SAVE")) {
        String strWindow = vars.getStringParameter("inpwindowId");
        String strLostReason = vars.getStringParameter("inplostreason");
        String strLostReasonText = vars.getStringParameter("inplostreasontext");
        String strAction2Do = vars.getStringParameter("inpproposalprocess");
        String strTargetDoctype = vars.getStringParameter("inpselecteddoctype");
        String strKey=vars.getStringParameter("inpKey");
        String strTab = vars.getStringParameter("inptabId");
      
        String strWindowPath = Utility.getTabURL(this, strTab, "R");
        if (strWindowPath.equals(""))
          strWindowPath = strDefaultServlet;
      
        OBError myMessage = processButton(vars, strKey, strAction2Do,strTargetDoctype,strLostReason,strLostReasonText, strWindow);
        vars.setMessage(strTab, myMessage);
        printPageClosePopUp(response, vars, strWindowPath);
      } else
        pageErrorPopUp(response);
}

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strKey,
               String windowId, String strTab, String strProcessId)
      throws IOException, ServletException {
    log4j.debug("Output: Button process Proposal Actions");
    String[] discard = {"newDiscard"};
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/erpCommon/ad_actionButton/ProposalActions", discard).createXmlDocument();
    xmlDocument.setParameter("key", strKey);
    xmlDocument.setParameter("window", windowId);
    xmlDocument.setParameter("tab", strTab);
    xmlDocument.setParameter("css", vars.getTheme());
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("processId", "D0731EC8815B4580BE1F5C2FD4311C55");
    xmlDocument.setParameter("cancel", Utility.messageBD(this, "Cancel", vars.getLanguage()));
    xmlDocument.setParameter("ok", Utility.messageBD(this, "OK", vars.getLanguage()));
    
    {
      OBError myMessage = vars.getMessage("D0731EC8815B4580BE1F5C2FD4311C55");
      vars.removeMessage("D0731EC8815B4580BE1F5C2FD4311C55");
      if (myMessage!=null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

   try {
      ComboTableData comboTableData = null;
      xmlDocument.setParameter("proposalprocess", "");
      // For Subscription-Offers that change Existing Order
      if (!ProposalActionsData.c_subscriptionofferchangeexisting(this,strKey).equals("FALSE")){
        comboTableData = new ComboTableDataWrapper(this,vars, "subscriptionprocess","");
        xmlDocument.setData("reportproposalprocess", "liststructure", comboTableData.select(false));
      } else {
	      // For Proposals...
	      if (ProposalActionsData.isSubscriptionOrder(this,strKey).equals("N")){
	        comboTableData = new ComboTableDataWrapper(this,vars, "proposalprocess","");
	        xmlDocument.setData("reportproposalprocess", "liststructure", comboTableData.select(false));
	        if (ProposalActionsData.isSubscriptionOffer(this, strKey).equals("N"))
	        	comboTableData = new ComboTableDataWrapper(this, vars,"soOffer2Ordertypes",null, windowId, "5D5792C53FBA46E2988653B6DC9FE5B4",null);
	        else
	        	comboTableData = new ComboTableDataWrapper(this, vars,"soOffer2SubscOrder",null, windowId, "ABE2033C7A74499A9750346A83DE3307",null);
	        xmlDocument.setData("reportselecteddoctype", "liststructure", comboTableData.select(false));
	      }
      }
      
      xmlDocument.setParameter("lostreason", "");
      comboTableData = new ComboTableDataWrapper(this,vars, "lostproposalfixedreason","");
      xmlDocument.setData("reportlostreason", "liststructure", comboTableData.select(false));
      xmlDocument.setParameter("lostreasontext", "");
    } catch (Exception ex) {
      throw new ServletException(ex);
    }
      out.println(xmlDocument.print());
      out.close();
  }
  
  private OBError   processButton(VariablesSecureApp vars, String strKey,String strAction2Do,String strTargetDoctype,String strLostReason,String strLostReasonText,String windowId) {
    String msg="";
    OBError myMessage = new OBError();
      try {
     
        // Actions
        // LO=Lost Proposal
        if (strAction2Do.equals("LO")){
          if (!strLostReason.isEmpty())
            msg=ProposalActionsData.markOfferAsLost(this, strKey, strLostReason, strLostReasonText, vars.getUser());
        }
        // VA= Create a variant
        if (strAction2Do.equals("VA"))
          msg=ProposalActionsData.createOfferVariant(this,strKey,vars.getUser() );
        // WO = Proposal won
        if (strAction2Do.equals("WO"))
         msg=ProposalActionsData.createOrderFromOffer(this,strKey,strTargetDoctype,vars.getUser());
        // CS= Change Subscription Contract
        if (strAction2Do.equals("CS"))
          msg=ProposalActionsData.changeSubscriptionOrderContract(this,strKey,vars.getUser());
        
      } catch (Exception e) {
        e.printStackTrace();
        log4j.warn("Rollback in transaction");
        msg="ERROR";
        myMessage = Utility.translateError(this, vars, vars.getLanguage(), e.getMessage());
      }
      if ((strAction2Do.equals("LO") && !strLostReason.isEmpty()) || !strAction2Do.equals("LO")){
		  String msgtext;
	      if (!strAction2Do.equals("LO") && !strAction2Do.equals("CS"))
	        msgtext=Utility.translate(this, vars, "DocumentCreated", vars.getLanguage());
	      else if (strAction2Do.equals("CS"))
	        msgtext=Utility.translate(this, vars, "ExistingDocumentChanged", vars.getLanguage());
	      else
	        msgtext=Utility.translate(this, vars, "ProposalLost", vars.getLanguage());
	      if (!msg.startsWith("ERROR"))
	        myMessage.setType("Success");
	      else {
	        myMessage.setType("Error");
	        msgtext="";
	      }
        myMessage.setTitle(msgtext + msg);
      } 
      else {
        myMessage.setType("Error");
        myMessage.setTitle(Utility.messageBD(this, "You need to give a reason for lost Orders", vars.getLanguage()));
      }      
    return myMessage;
  }
  public String getServletInfo() {
    return "Servlet ProposalActions";
  } // end of getServletInfo() method
}
