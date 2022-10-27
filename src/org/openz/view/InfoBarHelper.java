package org.openz.view;



import javax.servlet.http.HttpServletRequest;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.utils.Replace;
import org.openz.util.FormatUtils;
import org.openz.util.LocalizationUtils;
import org.openz.view.templates.ConfigureInfobar;

public class InfoBarHelper {

	
	public static String upperInfoBarApp(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script, String big1,String big2, String small1, String small2,  String small3) throws Exception { 
		String retval;
		String lefttext;
		String righttext;
		// Left
		String skeleton="<span style=\"font-size: 20pt; color: #000000;\">";
		lefttext=skeleton + big1 + "<br />" + big2 + "</span>";
		// Right
		skeleton="<span style=\"font-size: 14pt; color: #000000;\">";
		righttext=skeleton + small1 + "<br />" + small2 + "<br />" + small3+ "</span>";
		retval=ConfigureInfobar.doConfigure2Rows(servlet, vars, script, lefttext, righttext);		
		return retval;
	}
	public static String getSnrBnrStr(HttpSecureAppServlet servlet,VariablesSecureApp vars,String snr,String bnr,String qty, String wht) throws Exception { 
		String retval="";
		if(!FormatUtils.isNix(snr)	&& FormatUtils.isNix(bnr)) {
			retval=" Snr:" + snr + (FormatUtils.isNix(wht) ?"":"(" + wht + "kg)");
		}
		if(!FormatUtils.isNix(bnr)) {
			retval=(retval.isEmpty()?(LocalizationUtils.getElementTextByElementName(servlet, "pdc_qty", vars.getLanguage())+" :" + qty):"") + retval + LocalizationUtils.getElementTextByElementName(servlet, "pdc_btch", vars.getLanguage()) +":" +bnr;        					  
		}
		return retval;
	}
	

}
