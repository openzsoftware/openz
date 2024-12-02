/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License.
 * The Original Code is Openbravo ERP.
 * The Initial Developer of the Original Code is Openbravo SL
 * All portions are Copyright (C) 2007-2009 Openbravo SL
 * All Rights Reserved.
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.utility;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.sql.Connection;
import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.jasperreports.engine.JRException;

import net.sf.jasperreports.engine.JRParameter;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;

import net.sf.jasperreports.engine.design.JasperDesign;

import net.sf.jasperreports.engine.export.JRXlsExporter;

import net.sf.jasperreports.engine.xml.JRXmlLoader;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.Sqlc;
import org.openbravo.erpCommon.utility.reporting.DocumentType;
import org.openbravo.erpCommon.utility.reporting.Report;
import org.openbravo.erpCommon.utility.reporting.ReportManager;
import org.openbravo.erpCommon.utility.reporting.ReportingException;
import org.openbravo.erpCommon.utility.reporting.Report.OutputTypeEnum;
import org.openbravo.utils.FileUtility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.pdc.controller.DoProductionData;

import com.lowagie.text.Document;
import com.lowagie.text.pdf.PdfCopy;
import com.lowagie.text.pdf.PdfImportedPage;
import com.lowagie.text.pdf.PdfReader;

public class PrintJR extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  @SuppressWarnings("null")
public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    DateFormat df = new SimpleDateFormat("yyyy-MM-dd");
    DateFormat rn = new SimpleDateFormat("ddMMyy");
    String strProcessId = vars.getRequiredStringParameter("inpadProcessId");
    String strOutputType = vars.getStringParameter("inpoutputtype", "html");
    if (!hasGeneralAccess(vars, "P", strProcessId)) {
      bdError(request, response, "AccessTableNoView", vars.getLanguage());
      return;
    }

    String strReportName = PrintJRData.getReportName(this, strProcessId);
    HashMap<String, Object> parameters = createParameters(vars, strProcessId);
    Object parentryfmt=(String)parameters.get("Label");
    Object parentryoutput=(String)parameters.get("outputType");
    if (parentryoutput==null)
    	parentryoutput="pdf";
    if (parentryoutput.equals("xls")){
      String strplainReportName=strReportName.replace("@basedesign@", "");
      String path=this.getBaseDesignPath(vars.getLanguage());
      File f=new File(path + strplainReportName + "XLS.jrxml");
      if (f.exists())
        strReportName = PrintJRData.getReportName(this, strProcessId) + "XLS.jrxml";
    }
    
   

   //if(strProcessId.equals("B3CCA6F9411347AF97712A3F8664B3F7")){
   if(strProcessId.equals("93F39318941F41D0957A12D5C6135AF4")){
     if(parentryfmt.equals("qr25x25") && parentryoutput.equals("pdf")){
  	   strReportName="@basedesign@/org/openbravo/zsoft/smartui/printing/Rpt_Productlabel_24x24_single_shop.jrxml";
     }
     if (parentryfmt.equals("qr70x53") && parentryoutput.equals("pdf")){
  	   strReportName="@basedesign@/org/openbravo/zsoft/smartui/printing/Rpt_Productlabel_70x48_single_box.jrxml";
     }
     if (parentryfmt.equals("std57x31") && parentryoutput.equals("pdf")){
     strReportName="@basedesign@/org/openbravo/zsoft/smartui/printing/Rpt_Productlabel_57x31_single.jrxml";
     }
   }
   if(strProcessId.equals("06AAB5B7859B45DAAAF4B70F96771014") && (parentryoutput.equals("pdf"))){
	   
	   Date paradf =(Date)parameters.get("dateFrom");
	   Date paradt=(Date)parameters.get("dateTo");
	   Object paraoutput=(String)parameters.get("outputType");
	   
	   String sdaten=rn.format(paradf);
	   String edaten=rn.format(paradt);
	   String sdate=df.format(paradf);
	   String edate=df.format(paradt);
	   ArrayList<String> namedates = new ArrayList<String>();
	   namedates.add(sdaten);
	   namedates.add(edaten);
	   PrintJRData dates[] = PrintJRData.getDates(this, sdate, "yyyy-mm-dd hh24:mi:ss", edate);
	   
	   if (dates.length>=1){
			documents = new Vector();
			
			
	   for (int i = 0; i < dates.length; i++) {
			try {
				Levelpointer l = new Levelpointer();
				HashMap<String, Object> paras;
				paras=parameters;
				
				
				 String datefrom =dates[i].datebegin;
				    String dateto =dates[i].dateend;
				    
				    PrintJRData[] processparams = PrintJRData.getProcessParams(this, strProcessId);
				    String paramValue = "";
				    String strAttach = globalParameters.strFTPDirectory + "/284-" + classInfo.id;
				    String strLanguage = vars.getLanguage();
				    String strBaseDesign = getBaseDesignPath(strLanguage);

				      strReportName = Replace.replace(
				          Replace.replace(strReportName, "@basedesign@", strBaseDesign), "@attach@", strAttach);

				    	JasperDesign jasperDesign;
				jasperDesign = JRXmlLoader.load(strReportName);
				JasperReport jasperReport=null;
				jasperReport = JasperCompileManager.compileReport(jasperDesign);
				//jasperReport = JasperCompileManager.compileReport(jasperDesign);
			    paras.put("dateFrom", formatParameter(vars,
			    		"dateFrom", datefrom, "15", jasperReport));
			    paras.put("dateTo", formatParameter(vars,
			    		"dateTo", dateto, "15", jasperReport));
			    		l.id=i;
						l.value=new HashMap<String, Object>(paras);
						documents.add(l);
						
							   
					   
			    
			} catch (JRException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
				
			}
	       
		   doreports(vars, response, strReportName, strOutputType, null, null, documents.size(), namedates);
					

   }  
   
   }
   //compileReport2FileHelper();
   if(strProcessId.equals("06AAB5B7859B45DAAAF4B70F96771014")&& (!parentryoutput.equals("pdf")))
	   renderJR(vars, response, strReportName, strOutputType, parameters, null, null); 
   if(!strProcessId.equals("06AAB5B7859B45DAAAF4B70F96771014"))
	   renderJR(vars, response, strReportName, strOutputType, parameters, null, null); 
  }
   
  
  

  private HashMap<String, Object> createParameters(VariablesSecureApp vars, String strProcessId)
      throws ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("JR: Get Parameters");
    String strParamname;
    JasperReport jasperReport = null;

    HashMap<String, Object> parameters = new HashMap<String, Object>();
    PrintJRData[] processparams = PrintJRData.getProcessParams(this, strProcessId);
    if (processparams != null && processparams.length > 0) {
      String strReportName = PrintJRData.getReportName(this, strProcessId);
      String strAttach = globalParameters.strFTPDirectory + "/284-" + classInfo.id;
      String strLanguage = vars.getLanguage();
      String strBaseDesign = getBaseDesignPath(strLanguage);

      strReportName = Replace.replace(
          Replace.replace(strReportName, "@basedesign@", strBaseDesign), "@attach@", strAttach);

      try {
        JasperDesign jasperDesign = JRXmlLoader.load(strReportName);
        jasperReport = JasperCompileManager.compileReport(jasperDesign);
      } catch (JRException e) {
        if (log4j.isDebugEnabled())
          log4j.debug("JR: Error: " + e);
        e.printStackTrace();
        throw new ServletException(e.getMessage(), e);
      } catch (Exception e) {
        throw new ServletException(e.getMessage(), e);
      }

    }
    for (int i = 0; i < processparams.length; i++) {
      strParamname = "inp" + Sqlc.TransformaNombreColumna(processparams[i].paramname);
      String paramValue = "";

      if (Utility.isNumericParameter(processparams[i].reference)) {
        paramValue = vars.getNumericParameter(strParamname);
      } else {
    	  if (Utility.isDateTime(processparams[i].reference))
    		  paramValue = vars.getDateParameter(strParamname,this);
    	  else
    		  paramValue = vars.getStringParameter(strParamname);
      }

      if (log4j.isDebugEnabled()) {
        log4j.debug("JR: -----parameter: " + strParamname + " " + paramValue);
      }

      if (!paramValue.equals("")) {
        parameters.put(processparams[i].paramname, formatParameter(vars,
            processparams[i].paramname, paramValue, processparams[i].reference, jasperReport));
      }
    }
    return parameters;
  }

  private Object formatParameter(VariablesSecureApp vars, String strParamName,
      String strParamValue, String reference, JasperReport jasperReport) throws ServletException {
    String strObjectClass = "";
    Object object;
    JRParameter[] jrparams = jasperReport.getParameters();
    for (int i = 0; i < jrparams.length; i++) {
      if (jrparams[i].getName().equals(strParamName))
        strObjectClass = jrparams[i].getValueClassName();
    }
    if (log4j.isDebugEnabled())
      log4j.debug("ClassType: " + strObjectClass);
    if (strObjectClass.equals("java.lang.String")) {
      object = new String(strParamValue);
    } else if (strObjectClass.equals("java.util.Date")) {
      String strDateFormat;
      // strDateFormat = vars.getJavaDateFormat();
      strDateFormat = "dd-MM-yyyy";
      SimpleDateFormat dateFormat = new SimpleDateFormat(strDateFormat);
      try {
        object = dateFormat.parse(strParamValue);
      } catch (Exception e) {
        throw new ServletException(e.getMessage());
      }
    } else {
      object = new String(strParamValue);
    }
    return object;
  }
  private Vector <Levelpointer> documents;
private boolean multiReports= false;
private boolean archivedReports= false;
  class Levelpointer {
	int id; 
    public HashMap <String,Object> value;
    
  }






@SuppressWarnings("deprecation")
private void saveReport(VariablesSecureApp vars, JasperPrint jp,
	      Map<Object, Object> exportParameters, String fileName) throws JRException {
	    final String outputFile = globalParameters.strFTPDirectory + "/" + fileName;
	    final String reportType = fileName.substring(fileName.lastIndexOf(".") + 1);
	    	    	if (reportType.equalsIgnoreCase("pdf")) {
	      JasperExportManager.exportReportToPdfFile(jp, outputFile);
	    } else if (reportType.equalsIgnoreCase("xls")) {
	      JRXlsExporter exporter = new JRXlsExporter();
//	      exportParameters.put(JRExporterParameter.JASPER_PRINT, jp);
//	      exportParameters.put(JRExporterParameter.OUTPUT_FILE_NAME, outputFile);
//	      exportParameters.put(JExcelApiExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
//	      exportParameters.put(JExcelApiExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS,
//	          Boolean.TRUE);
//	      exportParameters.put(JExcelApiExporterParameter.IS_DETECT_CELL_TYPE, true);
//	      
	      
	      exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.JASPER_PRINT, jp);
	      exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.OUTPUT_FILE_NAME, outputFile);
	      exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
	      exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
	      exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
	      //exporter.setParameters(exportParameters);
	      exporter.exportReport();
	    } else {
	      throw new JRException("Report type not supported");
	    }}

	  
protected void doreports(VariablesSecureApp variables, HttpServletResponse response,
	      String strReportName, String strOutputType,
	      FieldProvider[] data, Map<Object, Object> exportParameters,int count, ArrayList<String> dates ) throws ServletException {
	   ArrayList <JasperPrint> jasperPrintList= new ArrayList<JasperPrint>();
	   HashMap<String, Object> paras;
	   ArrayList<String> filenames = new ArrayList<String>();
	   
	    if (strReportName == null || strReportName.equals(""))
	      strReportName = PrintJRData.getReportName(this, classInfo.id);

	    final String strAttach = globalParameters.strFTPDirectory + "/284-" + classInfo.id;

	    final String strLanguage = variables.getLanguage();
	    final Locale locLocale = new Locale(strLanguage.substring(0, 2), strLanguage.substring(3, 5));

	    final String strBaseDesign = getBaseDesignPath(strLanguage);

	    strReportName = Replace.replace(Replace.replace(strReportName, "@basedesign@", strBaseDesign),
	        "@attach@", strAttach);
	    final String strPathname = strReportName.substring(0, strReportName.lastIndexOf("/") +1);
	    String strFileName = strReportName.substring(strReportName.lastIndexOf("/") + 1);
	    ServletOutputStream os = null;
	    UUID reportId = null;
	   try {
		   
		   Connection con = null;
		     
	    	for (int i =0;i < documents.size();i++){
	 		   
	 		   paras=documents.elementAt(i).value;
	      JasperDesign jasperDesign = JRXmlLoader.load(strReportName);
	           
	      final JasperReport jasperReport = Utility.getTranslatedJasperReport(this, strReportName,
	          strLanguage, strBaseDesign);

	      Boolean pagination = true;
	      if (strOutputType.equals("pdf"))
	        pagination = false;

	      paras.put("IS_IGNORE_PAGINATION", pagination);
	      paras.put("BASE_WEB", strReplaceWithFull);
	      paras.put("BASE_DESIGN", strBaseDesign);
	      paras.put("ATTACH", strAttach);
	      paras.put("USER_CLIENT", Utility.getContext(this, variables, "#User_Client", ""));
	      paras.put("USER_ORG", Utility.getContext(this, variables, "#User_Org", ""));
	      paras.put("LANGUAGE", strLanguage);
	      paras.put("LOCALE", locLocale);
	      if (paras.get("REPORT_TITLE")!=null)
	        if (paras.get("REPORT_TITLE").equals(""))
	        	paras.put("REPORT_TITLE", PrintJRData.getReportTitle(this,
	          variables.getLanguage(), classInfo.id));

	      final DecimalFormatSymbols dfs = new DecimalFormatSymbols();
	      dfs.setDecimalSeparator(variables.getSessionValue("#AD_ReportDecimalSeparator").charAt(0));
	      dfs.setGroupingSeparator(variables.getSessionValue("#AD_ReportGroupingSeparator").charAt(0));
	      final DecimalFormat numberFormat = new DecimalFormat(variables
	          .getSessionValue("#AD_ReportNumberFormat"), dfs);
	      paras.put("NUMBERFORMAT", numberFormat);

	      if (log4j.isDebugEnabled())
	        log4j.debug("creating the format factory: " + variables.getJavaDateFormat());
	      final JRFormatFactory jrFormatFactory = new JRFormatFactory();
	      jrFormatFactory.setDatePattern(variables.getJavaDateFormat());
	      paras.put(JRParameter.REPORT_FORMAT_FACTORY, jrFormatFactory);
	       
	      JasperPrint jasperPrint;
	      try {
	        con = getTransactionConnection();
	        if (data != null) {
	        	paras.put("REPORT_CONNECTION", con);
	          jasperPrint = JasperFillManager.fillReport(jasperReport, paras,
	              new JRFieldProviderDataSource(data, variables.getJavaDateFormat()));
	          jasperPrintList.add(jasperPrint);
	        } else {
	          jasperPrint = JasperFillManager.fillReport(jasperReport, paras, con);
	          jasperPrintList.add(jasperPrint);
	        }
	      } catch (final Exception e) {
	        throw new ServletException(e.getMessage(), e);
	      } finally {
	        releaseRollbackConnection(con);
	      }
	    	}
	    	  for (int k=0;k<jasperPrintList.size();k++){
	      if (exportParameters == null){
	        exportParameters = new HashMap<Object, Object>();
	      }
	      if (strOutputType.equals("pdf") || strOutputType.equalsIgnoreCase("xls")) {
	        	
	        		reportId = UUID.randomUUID();
	        		JasperPrint report;
	        		report=jasperPrintList.get(k);
	        saveReport(variables, report, exportParameters, strFileName + "-" + k + "."
	            + strOutputType);
	        filenames.add(strFileName+ "-" + k + "." + strOutputType);	    	
        	

        	
	        } else {
            throw new ServletException("Output format no supported");
        }
      }{
      	concatenateReports(filenames, response, variables, dates);
        
      } }catch (final Exception e) {
	        throw new ServletException(e.getMessage(), e);
	      } 
    }


private void concatenateReports(ArrayList<String> filenames,HttpServletResponse response, VariablesSecureApp vars, ArrayList<String> dates ) {
    try {
      int pageOffset = 0;
      // ArrayList master = new ArrayList();
      int f = 0;
      String filename = "";
      if (filename == null || filename.equals("")) {
      		filename = "ResourcePlanCollection"+dates.get(0)+"_"+dates.get(1) +".pdf";
        if (filenames.size()>1) {
        	filename = "ResourcePlanCollection"+dates.get(0)+"_"+dates.get(1) +".pdf";
        } else {
          filename = filenames.get(f);
        }
      }
      if (filenames.size() == 1)
        filename = "ResourcePlanCollection"+dates.get(0)+"_"+dates.get(1) +".pdf";
      Document document = null;
      PdfCopy writer = null;
      File outfi = new File(filename);
      FileOutputStream fos= new FileOutputStream(globalParameters.strFTPDirectory + "/" + outfi);
      
    		  //response.getOutputStream();
   while (f < filenames.size()) {

        response.setHeader("Content-disposition", "attachment" + "; filename=" + filename);
        // we create a reader for a certain document
        PdfReader reader = new PdfReader( globalParameters.strFTPDirectory + "/" + filenames.get(f));
        reader.consolidateNamedDestinations();
        // we retrieve the total number of pages
        int n = reader.getNumberOfPages();
        pageOffset += n;

        if (f == 0) {
          // step 1: creation of a document-object
          document = new Document(reader.getPageSizeWithRotation(1));
          // step 2: we create a writer that listens to the document
          writer = new PdfCopy(document,fos );
          // step 3: we open the document
          document.open();
        }
        // step 4: we add content
        PdfImportedPage page;
        for (int i = 0; i < n;) {
          ++i;
          page = writer.getImportedPage(reader, i);
          writer.addPage(page);
        }
          File file = new File( globalParameters.strFTPDirectory + "/" + filenames.get(f));
          if (file.exists() && !file.isDirectory()) { 
            file.delete();
          }
        f++;
      }
      document.close();
      fos.close();
      
      response.setContentType("text/html;charset=UTF-8");
      response.setHeader("Content-disposition", "inline" + "; filename=" + filename);
      printPagePopUpDownloadFile( response.getOutputStream(),filename, "" );
    } catch (Exception e) {
      log4j.error(e);
    }
  }

public void printPagePopUpDownloadFile(ServletOutputStream os, String fileName, String fdir)
throws IOException, ServletException {
      if (log4j.isDebugEnabled())
        log4j.debug("Output: PopUp Download");
      String href = strDireccion + "/utility/DownloadFile.html?dfile=" + fileName + "&fdir=" + fdir;
      XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/base/secureApp/PopUp_Download").createXmlDocument();
      xmlDocument.setParameter("href", href);
      os.println(xmlDocument.print());
      os.close();
       
 }

public void compileReport2FileHelper()
 {
	  // Wenn ECLIPSE beim jasper compile wieder zickt....
      String strReportName="/home/openz/tomcat/webapps/openz//src-loc/design/org/openbravo/zsoft/smartui/printing/Bom_Lines_excel.jrxml";
      String strBaseDesign="/home/openz/tomcat/webapps/openz//src-loc/design"; 
      String strLanguage="de_DE";
      try {
      final JasperReport jasperReport = Utility.getTranslatedJasperReport(this, strReportName,
    	        strLanguage, strBaseDesign);
      }catch (Exception e) {
          log4j.error(e);
      }
 }



public String getServletInfo() {
    return "Servlet that generates the output of a JasperReports report.";
  } // end of getServletInfo() method
}
