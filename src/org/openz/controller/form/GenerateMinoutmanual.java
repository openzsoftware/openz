package org.openz.controller.form;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
//import org.openbravo.erpCommon.ad_forms.RequisitionToOrderData;
import org.openbravo.erpCommon.businessUtility.Tree;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.reference.ActionButtonData;
import org.openbravo.erpCommon.reference.PInstanceProcessData;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.DateTimeData;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.LocalizationUtils;
import org.openz.util.UtilsData;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;


public class GenerateMinoutmanual  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      Connection conn = null;
      Vector <String> retval;
            
      
      Scripthelper script= new Scripthelper();
      // After Changes ask the user for discarding them or remain on the site
      script.addHiddenfieldWithID("enabledautosave", "N");
      response.setContentType("text/html; charset=UTF-8");
      String strOutput ="" ;
      String strIsSOtrx=vars.getSessionValue("issotrx");
      String stradorgid = vars.getGlobalVariable("inpadOrgId",this.getClass().getName() +"|AD_ORG_ID",vars.getOrg());  
      String stroptions =strIsSOtrx.equals("Y")?vars.getSessionValue(this.getClass().getName() + "|options"):"";
      OBError myMessage = new OBError();
      
      // INIT by AD
      try{
        if (vars.commandIn("FIND")||vars.commandIn("DEFAULT") ){
          if (vars.commandIn("FIND"))
            // New Filter defined: Remove old Session Vars
            removeSessionValues(vars);
          // Set session  and read filter
          String strProductId=vars.getSessionValue(this.getClass().getName() + "|m_product_id");
          if (strProductId==null||vars.commandIn("FIND"))
            strProductId = vars.getInStringParameter("inpm_product_id");
          
          vars.setSessionValue(this.getClass().getName() + "|m_product_id", strProductId);
          //setSessionValue(this.getClass().getName() + "|m_product_id",  strProductId);
          String strdocno = vars.getGlobalVariable("inpdocumentno",
              this.getClass().getName() + "|Documentno", "");
          String strwh = vars.getGlobalVariable("inpmWarehouseId", this.getClass().getName() + "|m_warehouse_id", "");
          String strcProjectId = vars.getGlobalVariable("inpproject",
              this.getClass().getName() + "|Project", "");

          String strDatenow=vars.getSessionValue("#DATE");
          if (!vars.getSessionValue("P|INOUTMANUALINCOMINGDATEOFFSET").isEmpty() && strIsSOtrx.equals("N"))
        	  strDatenow=GenerateMinoutmanualData.adddate(this, vars.getSessionValue("P|INOUTMANUALINCOMINGDATEOFFSET"));
          if (!vars.getSessionValue("P|INOUTMANUALOUTGOINGDATEOFFSET").isEmpty() && strIsSOtrx.equals("Y"))
        	  strDatenow=GenerateMinoutmanualData.adddate(this, vars.getSessionValue("P|INOUTMANUALOUTGOINGDATEOFFSET"));
          String strDateFrom = vars.getDateParameterGlobalVariableAndFetchFromSessionIfEmpty("inpdatefrom", this.getClass().getName() + "|datefrom", this);
          String strDateTo = vars.getDateParameterGlobalVariableAndFetchFromSessionIfEmpty("inpdateto", this.getClass().getName() + "|dateto",  strDatenow,this);
          String strBusinesspartnerId = vars.getGlobalVariable("inpcBpartnerId", this.getClass().getName() + "|C_Bpartner_ID","");    
          stroptions=strIsSOtrx.equals("Y")?vars.getGlobalVariable("inpoptions", this.getClass().getName() + "|options",vars.getSessionValue("P|INOUTMANUALOUTGOINGOPTIONDEFAULT")):"";
          String strOnlydeliverable="1";
          if (stroptions.equals("DELONLY")) // Alle Lieferbaren Pos.
            strOnlydeliverable="2";
          String strTypeOfProduct = vars.getGlobalVariable("inpproductclassification", this.getClass().getName() + "|productclassification", "");
          String strPartlydeliverable = vars.getGlobalVariable("inppartlydelivery", this.getClass().getName() + "|partlydelivery", "");
          if (strPartlydeliverable.equals("")) strPartlydeliverable="N"; else 	strPartlydeliverable="Y";
          String strCombineddelivery = vars.getGlobalVariable("inpcombineddelivery", this.getClass().getName() + "|combineddelivery", "");
          if (strCombineddelivery.equals("")) strCombineddelivery="N"; else 	strCombineddelivery="Y";
          String strProductCategoryId ="";
          // Either type of product or category...
          if (strTypeOfProduct.length()==32) {
            strProductCategoryId=strTypeOfProduct;
            strTypeOfProduct="";
          }
          String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
          WindowTabs tabs;
          if (strIsSOtrx.equals("Y"))
            tabs = new WindowTabs(this, vars, "org.openz.controller.form.GenerateMinoutmanualSO");
          else
            tabs=new WindowTabs(this, vars, "org.openz.controller.form.GenerateMinoutmanualPO");
          String title=LocalizationUtils.getElementTextByElementName(this, strIsSOtrx.equals("Y") ? "Generate Shipments manual" : "Generate material receipts manual", vars.getLanguage());
          strOutput =ConfigureFrameWindow.doConfigure(this,vars,"",null, title,strToolbar,"NONE",tabs); 
          String strTableStructure = ConfigureTableStructure.doConfigure(this,vars,"6","100%" ,"Main");
         // String strTableCells=ConfigureFieldgroup.doConfigure(this,vars,script,"Process","6", "");
          // Filter structure   
          Formhelper fh = new Formhelper();
          String filterStructure=fh.prepareFieldgroup(this, vars, script, "Generate Shipments manual filter", null,false);
          filterStructure=Replace.replace(filterStructure, "id=\"m_product_idlbltdx\"", "id=\"m_product_idlbltdx\" style=\"top: -50px !important;position: relative;\"");
          filterStructure=Replace.replace(filterStructure, "id=\"m_product_idtdx\"","id=\"m_product_idtdx\" style=\"top: -50px !important;position: relative;\"");
          //Direct Filter Functions
          filterStructure=Replace.replace(filterStructure, "changeToEditingMode('onkeypress'); return true;", ""); // Remove for PopupSelector
          filterStructure=Replace.replace(filterStructure, "changeToEditingMode('onkeypress');", "aceptar(event);"); // add on all others
          String buttonprocess=fh.prepareFieldgroup(this, vars, script, "Generate Shipments Manual Process", null,false);
          //String strAction="submitCommandForm('SAVE', true, null,'" + this.strDireccion + "/org.openz.controller.ad_forms/GenerateMinoutmanual.html', 'appFrame', false, true)";
          //strTableCells=strTableCells + ConfigureButton.doConfigure(this, vars,script, "Process", 1, 3,false,  "process", strAction, "Process");
          strTableStructure = "";//Replace.replace(strTableStructure, "@CONTENT@", strTableCells);  
          // Initialize the Grid
          EditableGrid grid;
          if (strIsSOtrx.equals("Y")) {
             grid = new EditableGrid("Generate Shipments manual Grid", vars, this);           
          }else{
             grid = new EditableGrid("Generate Shipments manual incoming Grid", vars, this);
          };
          //GenerateMinoutmanualData[] data=GenerateMinoutmanualData.select(this);
          //String strGrid=grid.printGrid(this, vars, script, data);
          String strTreeOrg = GenerateMinoutmanualData.treeOrg(this, vars.getClient());            
          String orglist=Tree.getMembers(this, strTreeOrg, stradorgid);
          String strUserOrg=Utility.getContext(this, vars,"#User_Org", "GenerateInoutmanual");
          String strGrid1="";
          String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
          if (!(vars.commandIn("DEFAULT") && UtilsData.getOrgConfigOption(this, "alwaysfilterocreatetrxs", vars.getOrg()).equals("Y"))) {
        	  GenerateMinoutmanualData datalines[];
        	  if (stroptions.equals("DELBYPRIORITY") || stroptions.equals("DELBYLOCATOR")) {
        		  datalines=GenerateMinoutmanualData.selectOptions(this, strBusinesspartnerId, strDateFrom, strDateTo,strdocno,strcProjectId,strwh,orglist, strUserOrg,strProductId, strTypeOfProduct,strProductCategoryId,
        				  stroptions,strCombineddelivery,strPartlydeliverable,strDateFormat,vars.getLanguage());
        	  } else {
	        	  if (strCombineddelivery.equals("N"))
	        		  datalines=GenerateMinoutmanualData.select(this,strDateFormat,vars.getLanguage(),strPartlydeliverable, strdocno,strcProjectId, strDateFrom, strDateTo, strBusinesspartnerId,
	        				  strTypeOfProduct,strProductCategoryId,strwh, orglist, strUserOrg, strIsSOtrx, strProductId,strOnlydeliverable);
	        	  else
	        		  datalines=GenerateMinoutmanualData.selectCombined(this,strDateFormat,strPartlydeliverable, vars.getLanguage(),strdocno,strcProjectId, strDateFrom, strDateTo, strBusinesspartnerId,
	        				  strTypeOfProduct,strProductCategoryId,strwh, orglist, strUserOrg, strIsSOtrx, strProductId,strOnlydeliverable);
        	  }
              strGrid1=grid.printGrid(this, vars, script, datalines);
          }
          strOutput=Replace.replace(strOutput, "@CONTENT@",  filterStructure + strGrid1 + strTableStructure + buttonprocess);
          script.addOnload("setProcessingMode('window', false);");
          // Filter Action on Return
          script.addFilterAction4ManualServlets("submitCommandForm('FIND',true,null,null,'_self');");
          strOutput = script.doScript(strOutput, "",this,vars);
          PrintWriter out = response.getWriter();
          out.println(strOutput);
          out.close(); 
        }
        
        
        
        
       if (vars.commandIn("SAVE")) {
         conn= this.getTransactionConnection();
         EditableGrid grid;
         if (strIsSOtrx.equals("Y")) {
            grid = new EditableGrid("Generate Shipments manual Grid", vars, this);           
         }else{
            grid = new EditableGrid("Generate Shipments manual incoming Grid", vars, this);
         };

         retval=grid.getSelectedIds(null, vars, "c_orderline_id");
         String ordline,strOrderId,ordlineQty,ordlineLocatorId,ordlineAttributesetId,ordlineComplete,mProductID;
         String pinstance = SequenceIdData.getUUID();
         // Filters
         String strCombineddelivery = vars.getSessionValue( this.getClass().getName() + "|combineddelivery");
         String strdocno = vars.getSessionValue(this.getClass().getName() + "|Documentno");
         String strwh = vars.getSessionValue(this.getClass().getName() + "|m_warehouse_id");
         String strcProjectId = vars.getSessionValue(this.getClass().getName() + "|Project");
         String strDateFrom = vars.getSessionValue(this.getClass().getName() + "|DateFrom");
         String strDateTo = vars.getSessionValue(this.getClass().getName() + "|DateTo");
         String strUserOrg=Utility.getContext(this, vars,"#User_Org", "GenerateInoutmanual");
         for (int i = 0; i < retval.size(); i++) {
            if (strCombineddelivery.equals("N")||strCombineddelivery.equals("")||stroptions.equals("DELBYLOCATOR")) {
	           ordline=retval.elementAt(i).substring(0,32);
	           strOrderId=GenerateMinoutmanualData.getOrder(myPool, ordline);
	           //grid.getValue(this, vars, retval.elementAt(i), "C_Order_ID");
	           ordlineQty=grid.getValue(this, vars, retval.elementAt(i), "qty2deliver");
	           ordlineLocatorId=grid.getValue(this, vars, retval.elementAt(i), "m_locator_id");
	           ordlineAttributesetId=grid.getValue(this, vars, retval.elementAt(i), "m_attributesetinstance_id");
	           ordlineComplete=grid.getValue(this, vars, retval.elementAt(i), "completed");
	           // In SEts Relevant BOM Product while Order is SET product... Product ID is only Filled by Option DELBYLOCATOR or DELBYPRIORITY
	           mProductID=grid.getValue(this, vars, retval.elementAt(i), "m_product_id"); 
               GenerateMinoutmanualData.insert(conn,this, 
                  ordline,
                  strOrderId,
                  vars.getClient(), vars.getOrg(), vars.getUser(), vars.getUser(),
                  ordlineQty,
                  ordlineLocatorId,
                  ordlineAttributesetId,
                  ordlineComplete,
                  pinstance,mProductID.equals("null")?null:mProductID); 
            } else { // Combined Delivery - is determined by Order in GRID / Exception DELBYLOCATOR: Combined is done with m_inout_create
            	ordline=retval.elementAt(i);
            	String strDateFormat = vars.getSessionValue("#AD_SqlDateFormat");
            	String bpartner = ordline.substring(0,32);
            	String product = " ('"+ ordline.substring(32,64) + "')";
            	Double qty=0.0;
            	ordlineQty=grid.getValue(this, vars, retval.elementAt(i), "qty2deliver");
            	ordlineLocatorId=grid.getValue(this, vars, retval.elementAt(i), "m_locator_id");
            	ordlineAttributesetId=grid.getValue(this, vars, retval.elementAt(i), "m_attributesetinstance_id");
            	mProductID=grid.getValue(this, vars, retval.elementAt(i), "m_product_id");
            	GenerateMinoutmanualData datalines[]=GenerateMinoutmanualData.select(this,strDateFormat,vars.getLanguage(),"N", strdocno,strcProjectId, strDateFrom, strDateTo, bpartner,
      				  "","",strwh, strUserOrg, strUserOrg, strIsSOtrx, product,"1");
            	for (int ii=0;ii<datalines.length;ii++) {
            		if (qty<Double.parseDouble(ordlineQty)) {
            			String toDo=datalines[ii].qty2deliver;
            			if ((Double.parseDouble(toDo) + qty)>Double.parseDouble(ordlineQty))
            				toDo=Double.valueOf(Double.parseDouble(ordlineQty)-qty).toString();
            			qty=qty+Double.parseDouble(toDo);
            			GenerateMinoutmanualData.insert(conn,this, 
            				  datalines[ii].cOrderlineId,
            				  datalines[ii].cOrderId,
  	                          vars.getClient(), vars.getOrg(), vars.getUser(), vars.getUser(),
  	                          toDo,
  	                          ordlineLocatorId,
  	                          ordlineAttributesetId,
  	                          "C",
  	                          pinstance,mProductID.equals("null")?null:mProductID); 
            		}
            	}
            }
         }   
         releaseCommitConnection(conn);
         
         // m_inout_create
         PInstanceProcessData.insertPInstance(this, pinstance, "199", "0", "N", vars.getUser(), vars
             .getClient(), vars.getOrg());
         PInstanceProcessData.insertPInstanceParam(this, pinstance, "1", "Selection", stroptions.isEmpty()?"Y":stroptions, vars
             .getClient(), vars.getOrg(), vars.getUser());
         if (strCombineddelivery.equals("Y")&&stroptions.equals("DELBYLOCATOR"))
        	 PInstanceProcessData.insertPInstanceParam(this, pinstance, "2", "Combined", "Y", vars
                     .getClient(), vars.getOrg(), vars.getUser());
         ActionButtonData.process199(this, pinstance);

         try {
           PInstanceProcessData[] pinstanceData = PInstanceProcessData.select(this, pinstance);
           myMessage = Utility.getProcessInstanceMessage(this, vars, pinstanceData);
         } catch (Exception e) {
           myMessage = Utility.translateError(this, vars, vars.getLanguage(), e.getMessage());
           e.printStackTrace();
           log4j.warn("Error");
         }
         //GenerateShipmentsmanualData.updateReset(this, strSalesOrder);

         if (log4j.isDebugEnabled())
           log4j.debug(myMessage.getMessage());
         // new message system
         vars.setMessage(this.getClass().getName(), myMessage);
         response.sendRedirect(strDireccion + request.getServletPath());
         GenerateMinoutmanualData.deleteerror(this, pinstance);
       }
      } 
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
        try {
            releaseRollbackConnection(conn);
        } catch (final Exception ignored) {
        }
        throw new ServletException(e);
      }
      
    }
  

    private void removeSessionValues(VariablesSecureApp vars ){
      vars.removeSessionValue(this.getClass().getName() + "|Documentno");
      vars.removeSessionValue(this.getClass().getName() + "|Project");
      vars.removeSessionValue(this.getClass().getName() + "|DateFrom");
      vars.removeSessionValue(this.getClass().getName() + "|DateTo");
      vars.removeSessionValue(this.getClass().getName() + "|c_bpartner_id");
      vars.removeSessionValue(this.getClass().getName() + "|m_warehouse_id");
      vars.removeSessionValue(this.getClass().getName() + "|onlydeliverablelines");
      vars.removeSessionValue(this.getClass().getName() + "|partlydelivery");
      vars.removeSessionValue(this.getClass().getName() + "|combineddelivery");
      vars.removeSessionValue(this.getClass().getName() + "|productclassification");
      vars.removeSessionValue(this.getClass().getName() + "|options");
      
    }
    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

