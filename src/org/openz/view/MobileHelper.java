package org.openz.view;

import java.util.Enumeration;

import javax.servlet.http.HttpServletRequest;

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.utils.Replace;

public class MobileHelper {

	
	public static String addMobileCSS(HttpServletRequest request, String content) {
		String retval=content;
		if (isMobile(request)) {
        	retval=Replace.replace(retval, "Button_text", "Button_text Text_mobile ButtonHeight_mobile");
        	retval=Replace.replace(retval, "DataGrid_Header", "DataGrid_Header Text_mobile");
        	retval=Replace.replace(retval, "DataGrid_Content", "DataGrid_Content_mobile");       
        	retval=Replace.replace(retval, "class=\"Label\"","class=\"Label LabelText_mobile\"");
        }
		return retval;
	}
	
	public static boolean isMobile(HttpServletRequest request) {
		String ua=request.getHeader("User-Agent");
		//Enumeration<java.lang.String> ha=request.getHeaderNames();
		if (ua.toLowerCase().contains("android")) {
        	return true;
        }
		return false;
	}
	
	public static void setMobileMode(HttpServletRequest request,VariablesSecureApp vars,Scripthelper script) {
		if (isMobile(request)) {
			vars.setSessionValue("#ISMOBILE", "TRUE");
			script.addHiddenfield("strismobile", "Y");
			if (isScreenUpright(vars))
				script.addOnload("document.body.style.zoom = \"200%\";");
		}else
			vars.setSessionValue("#ISMOBILE", "FALSE");
				
	}
	
	public static boolean isScreenUpright(VariablesSecureApp vars) {
		int xi=Integer.parseInt(vars.getSessionValue("#ScreenX"));
	      int yi=Integer.parseInt(vars.getSessionValue("#ScreenY"));
	      if (yi>xi) 
	    	  return true;
	      else
		return false;
	}
	
	public static String addDummyFocus(String content) {
		String retval=content;
		//Field dummyfocusfield must exist and be the first field in form!
		retval=Replace.replace(retval, "id=\"dummyfocusfieldlbltd\">dummyfocusfield", ">");
		retval=Replace.replace(retval, "name=\"inpdummyfocusfield\" id=\"dummyfocusfield\"", "name=\"inpdummyfocusfield\" id=\"dummyfocusfield\" style=\"position:absolute;top:-200px\" ");
		return retval;
		// Hide Barcode... position:absolute;top:-250px;width:40px
	}
	
	public static String addcrActionBarcode(String content) {
		String retval=content;
		//Field pdcmaterialconsumptionbarcode must exist in Fieldgroup
		retval=Replace.replace(retval,"id=\"pdcmaterialconsumptionbarcode\" title=\"\" readonly=\"true\" onfocus=\"isGridFocused = false;\" onkeydown=\"changeToEditingMode('onkeydown');\"","id=\"pdcmaterialconsumptionbarcode\" title=\"\" readonly=\"true\" onfocus=\"isGridFocused = false;\" onkeydown=\"crAction(event);\"");
		return retval;
	}
	
	public static String hideActionBarcode(String content) {
		String retval=content;
		//Field pdcmaterialconsumptionbarcode must exist in Fieldgroup
		retval=Replace.replace(retval,"id=\"pdcmaterialconsumptionbarcodelbltd\">Barcode<","id=\"pdcmaterialconsumptionbarcodelbltd\"><");		
		retval=Replace.replace(retval,"input style=\"\" class=\"dojoValidateValid cellreadonly inputWidth\"  type=\"text\" maxlength=\"1000\" name=\"inppdcmaterialconsumptionbarcode\"","input style=\"position:absolute;top:-250px;width:40px\" class=\"dojoValidateValid cellreadonly inputWidth\"  type=\"text\" maxlength=\"1000\" name=\"inppdcmaterialconsumptionbarcode\"");
		return retval;
	}
	/*
	 * Sets all the necessary Responsive Settings for Scanner
	 * Needs a fieldgroup with field pdcmaterialconsumptionbarcode and dummyfocusfield
	 */
	public static String setMobileModeAndScanActionBarcode(HttpServletRequest request,VariablesSecureApp vars,Scripthelper script, String fieldgroup) {
		String retval=fieldgroup;
		// GUI Settings Responsive for Mobile Devises
	    // Prevent Softkeys on Mobile Devices (Field is Readonly and programmatically set). Field dummyfocusfield must exist (see MobileHelper.addDummyFocus)
		script.addOnload("setTimeout(function(){document.getElementById(\"pdcmaterialconsumptionbarcode\").focus();fieldReadonlySettings('pdcmaterialconsumptionbarcode', false);},50);");
	    script.addHiddenfieldWithID("forcefocusfield", "pdcmaterialconsumptionbarcode"); // Force Focus after Numpad to given Field
	    if (MobileHelper.isMobile(request)) {
	    	  MobileHelper.setMobileMode(request, vars, script);
	    	  retval=MobileHelper.addcrActionBarcode(retval);
	    	  if (MobileHelper.isScreenUpright(vars))
	  	    	retval=MobileHelper.hideActionBarcode(retval);
	    }	
	    // Settings for dummy focus...
	    retval=MobileHelper.addDummyFocus(retval);
	    return retval;	    
	}
}
