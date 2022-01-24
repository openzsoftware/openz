package org.openz.view.templates;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.utils.Replace;
import org.openz.util.LocalizationUtils;
import org.openz.view.Scripthelper;

public class ConfigureListBasedEntry {
	
	 public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String fieldname, String elementId,String currentvalue, boolean isGrid,int colstotal,String eventhandler, String style) throws Exception{
		    StringBuilder retval= new StringBuilder();
		    StringBuilder tempval= new StringBuilder();
		    String text;
		    String xmllabel = "<td colspan=\"@NUMCOLS@\" class=\"@CLASS@\" id=\"@FIELDNAME@td\"><div class=\"Label\"  style=\"@STYLE@\" id=\"@FIELDNAME@\" @EVENT@>@CURRENTVALUE@</div></td>";
		    if (! isGrid) {
		    	tempval.append(xmllabel);
		    	Replace.replace(tempval, "@NUMCOLS@", "1");
		    	Replace.replace(tempval, "@STYLE@", "");
		    	Replace.replace(tempval, "@EVENT@", "");
		    	Replace.replace(tempval, "@FIELDNAME@", fieldname + "lbl");
		    	Replace.replace(tempval, "@CLASS@", "Label_ListBased");
		    	if (elementId.equals(""))
		            text = LocalizationUtils.getElementTextByElementName(servlet, fieldname, vars.getLanguage());
		          else
		            text = LocalizationUtils.getElementTextById(servlet, elementId, vars.getLanguage());
		    	Replace.replace(tempval, "@CURRENTVALUE@", text);
		    	retval.append(tempval);
		    }
		    tempval= new StringBuilder();
		    tempval.append(xmllabel);
		    Replace.replace(tempval, "@NUMCOLS@", Integer.toString(colstotal-1));
		    Replace.replace(tempval, "@STYLE@", style);
	    	Replace.replace(tempval, "@EVENT@", eventhandler);
	    	Replace.replace(tempval, "@FIELDNAME@", fieldname );
	    	if ( isGrid) 
	    		Replace.replace(tempval, "@CLASS@", "DataGrid_ListBased");	
	    	else
	    		Replace.replace(tempval, "@CLASS@", "Form_ListBased");	
	    	Replace.replace(tempval, "@CURRENTVALUE@", currentvalue);
	    	retval.append(tempval);

		    return retval;
	 }
}
