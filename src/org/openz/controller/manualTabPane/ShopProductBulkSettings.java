package org.openz.controller.manualTabPane;

import java.sql.Connection;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.ToolBar;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.ManualTabPane;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFrameWindow;

public class ShopProductBulkSettings  implements ManualTabPane{

  public String getFormEdit(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,WindowTabs tabs,HttpServletResponse response,ToolBar stdtoolbar) throws Exception{
    String toolbarid=FormhelperData.getTabEditionToolbar(servlet,servlet.getClass().getName());
    Scripthelper script = new Scripthelper();
    
    String strOrgid=vars.getSessionValue(vars.getStringParameter("inpwindowId") + "|ad_org_id");
    script.addHiddenfield("inpadOrgId", strOrgid);
    String strCommand=vars.getStringParameter("inpCommandType");
    servlet.setCommandtype("");
    String strUser=vars.getUser();
   
    String msg="";
    String msgType="SUCCESS";
    String msgHeader="Success";
    
    try {
      
      // PICKLIST-ACTION
      if (strCommand.equals("PICKLIST")) {
        Vector <String> retval;
       
        retval=vars.getListFromInString(vars.getInStringParameter("inpproductlist"));
        //String strhidden=vars.getStringParameter("inphidden");
        String strhidden=vars.getGlobalVariable("inphidden", vars.getStringParameter("inpwindowId") + "|hidden","");
        String strshopid=vars.getStringParameter("inpzseShopId");
        //String strallworderonnostock=vars.getStringParameter("inpallworderonnostock");
        String strallworderonnostock=vars.getGlobalVariable("inpallworderonnostock", vars.getStringParameter("inpwindowId") + "|allworderonnostock","");
        //String strhideonnostock=vars.getStringParameter("inphideonnostock");
        String strhideonnostock=vars.getGlobalVariable("inphideonnostock",vars.getStringParameter("inpwindowId") + "|hideonnostock","");
        //String strmaxorderqty=vars.getNumericParameter("inpmaxorderqty");
        String strmaxorderqty=vars.getGlobalVariable("inpmaxorderqty", vars.getStringParameter("inpwindowId") + "|maxorderqty","");
        //String strminorderqty=vars.getNumericParameter("inpminorderqty");
        String strminorderqty=vars.getGlobalVariable("inpminorderqty", vars.getStringParameter("inpwindowId")+ "|minorderqty","");
        //String strmaxstockshown=vars.getNumericParameter("inpmaxstockshown");
        String strmaxstockshown=vars.getGlobalVariable("inpmaxstockshown", vars.getStringParameter("inpwindowId") + "|maxstockshown","");
        //String strminstockshown=vars.getNumericParameter("inpminstockshown");
        String strminstockshown=vars.getGlobalVariable("inpminstockshown",vars.getStringParameter("inpwindowId") + "|minstockshown","");
        //String strcateg=vars.getStringParameter("inpzseWebshopcategoryId");
        String strcateg=vars.getGlobalVariable("inpzseWebshopcategoryId", vars.getStringParameter("inpwindowId") + "|zse_Webshopcategory_Id","");
        //String strtag=vars.getStringParameter("inpzseTagProductId");
        String strtag=vars.getGlobalVariable("inpzseTagProductId", vars.getStringParameter("inpwindowId") + "|zse_Tag_Product_Id","");
        for (int i = 0; i < retval.size(); i++) {
          String strproductid=retval.elementAt(i);
          ShopProductBulkSettingsData.insert(servlet, strUser, strshopid, strproductid, strcateg, strtag, strhidden, 
              strhideonnostock, strallworderonnostock, strmaxstockshown, strminorderqty, strmaxorderqty,strminstockshown);
          if (msg.isEmpty())
            msg=Integer.toString(retval.size()) + " " + Utility.messageBD(servlet, "zse_BulkUpdateSucessfull",vars.getLanguage());
        }   
        
        }
      
    } catch (final ServletException ex) {
        final OBError myError = Utility.translateError(servlet, vars, vars.getLanguage(), ex.getMessage());
        msg=myError.getMessage();
        msgHeader=myError.getTitle();
        msgType=myError.getType();       
    }
    
    String strLeftabsmode=FormhelperData.getLeftTabsMode4Tab(servlet,servlet.getClass().getName());
    if (!msg.equals(""))
      script.addMessage(servlet, vars, msgType, msgHeader,msg);
    String strSkeleton = ConfigureFrameWindow.doConfigureWindowMode(servlet,vars,"description",tabs.breadcrumb(), "Test Form Window",toolbarid,strLeftabsmode,tabs,"_Relation",null);
    Formhelper fh=new Formhelper();
   
    String strTableStructure=fh.prepareFieldgroup(servlet, vars, script, "BulkProductShopAssignmentFG",null,true);
    strSkeleton=Replace.replace(strSkeleton, "@CONTENT@", strTableStructure );  
    // Add Search Shortcut
    if (!msg.equals(""))
      script.addMessage(servlet, vars, msgType, msgHeader,msg);
    script.addHiddenfieldWithID("enabledautosave", "N");
    strSkeleton = script.doScript(strSkeleton, "",servlet,vars);
    return strSkeleton;
  }
  public void setFormSave(HttpSecureAppServlet servlet,VariablesSecureApp vars,FieldProvider data,Connection con){
	  
  }
}
