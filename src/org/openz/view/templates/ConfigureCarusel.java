package org.openz.view.templates;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openz.util.LocalizationUtils;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;

public class ConfigureCarusel {
	public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String currentvalue, FormhelperData[] data,FieldProvider fielddata) throws Exception{
	    return doConfigureAll(servlet,vars,script,currentvalue, data, fielddata);	    
	}
	 
	  
	  private static StringBuilder doConfigureAll(HttpSecureAppServlet servlet,VariablesSecureApp vars,Scripthelper script,String currentvalue, FormhelperData[] fdata,FieldProvider fielddata) throws Exception{
	    StringBuilder retval= new StringBuilder();
	    final String directory= servlet.strBasePath;
	    
	    Object template;
	    template=  servlet.getServletContext().getAttribute("carouselTEMPLATE");
	    if (template==null) {
	    	  template = new String(FileUtils.readFile("Carousel.xml", directory + "/src-loc/design/org/openz/view/templates/"));
	    	  servlet.getServletContext().setAttribute("carouselTEMPLATE", template);
	    }    
	    
	    retval.append(template.toString());
	      //FileUtils.readFile("Textbox.xml", directory + "/src-loc/design/org/openz/view/templates/");
	    String text = LocalizationUtils.getElementTextByElementName(servlet, "previous", vars.getLanguage());
	    Replace.replace(retval, "@PREV@", text);
	    text = LocalizationUtils.getElementTextByElementName(servlet, "next", vars.getLanguage());
	    Replace.replace(retval, "@NEXT@", text);
	    String idValue="";
	    for (int i=0;i<fdata.length;i++) {
	    	if (fdata[i].template.equals("IDFIELD"))
	    		idValue=fielddata.getField(fdata[i].name);
	    }
	    CarouselData[] data=CarouselData.selectfromField(servlet, currentvalue,idValue);
	    String listtarget="";
	    String inner="";
	    for (int i=0;i<data.length;i++) {
	    	if (i==0) {
	    		listtarget="<span class=\"dot\" onclick=\"currentSlide(1)\"></span>";
	    		inner="<div id=\"firstimg\" class=\"mySlides fade\">"
	    				+ "<img class=\"carouselimg\" src=\"../utility/ShowImage?id="+ data[i].cFileId + "\" alt=\"Slide:" + Integer.toString(i) +"\">"+
	    				"</div>";
	    	} else {
	    		listtarget=listtarget + 
	    				"<span class=\"dot\" onclick=\"currentSlide("+  Integer.toString(i+1) + ")\"></span>";
	    		inner=inner+"<div class=\"mySlides fade\">" +
	    				"<img class=\"carouselimg\" src=\"../utility/ShowImage?id="+ data[i].cFileId + "\" alt=\"Slide:" + Integer.toString(i) +"\">" +
	    				"</div>";
	    	}	
	    }
	    Replace.replace(retval, "@LISTTARGETS@", listtarget);
	    Replace.replace(retval, "@INNER@", inner);
	    return retval;
	  }
}
