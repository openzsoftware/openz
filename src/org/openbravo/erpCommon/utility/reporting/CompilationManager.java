package org.openbravo.erpCommon.utility.reporting;

import java.io.File;
import java.sql.SQLException;
import java.text.DateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Vector;

import org.apache.commons.io.FilenameUtils;
import org.apache.log4j.Logger;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.ExecuteQuery;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JRParameter;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.engine.xml.JRXmlLoader;

public class CompilationManager {
  private static Logger log4j = Logger.getLogger(ReportManager.class);
  private static final String TEMP_REPORT_DIR = "tmp";

  private static ConnectionProvider _connectionProvider;
  private static String _language;
  

  public CompilationManager(ConnectionProvider connectionProvider, String language) {
	 _connectionProvider = connectionProvider;
	 _language = language;
  }

  public JasperReport compileReport(String pathToJrxmlFile,
		  String templateLocation,
		  String baseDesignPath,
		  String pocDocTypeId,
		  String printoutLastUpdated,
		  HashMap<String, Object> designParameters)
		  throws Exception {
	  

	  String pathToJasperFile = createJasperMainReportFileName(pathToJrxmlFile, pocDocTypeId, printoutLastUpdated);

	  return chooseCompilationProcessAndCompile(
			  pathToJasperFile, 
			  pathToJrxmlFile,
			  templateLocation,
			  baseDesignPath,
			  printoutLastUpdated,
			  designParameters);
  }
  
  static private String createJasperMainReportFileName(String pathToJRXMLFile, String pocDoctypeId, String printoutLastUpdated) {

	  return 
			  FilenameUtils.removeExtension(pathToJRXMLFile) + 
			  											 "_" +
			  									   	     pocDoctypeId +
			  									   	     "_" +
			  									   _language +
			  									   	     "_" +
			  									   	     printoutLastUpdated +
			  									   ".jasper"; 
  }

  static private String createJasperSubReportFileName(String pathToJRXMLFile) {

	  return 
			  FilenameUtils.removeExtension(pathToJRXMLFile) + 
			  											 "_" +
			  									   _language +
			  									   ".jasper"; 
  }
  
  static private JasperReport chooseCompilationProcessAndCompile(String pathToJasperFile,
		  String pathToJrxmlFile,
		  String templateLocation,
		  String baseDesignPath,
		  String printoutLastUpdated,
		  HashMap<String, Object> designParameters)
		  throws Exception {
	  

	  // compilierte Version zurückgeben
	  if(new File(pathToJasperFile).isFile()) {
		  return getMainReportFromJasperFile(pathToJasperFile, templateLocation,
				  baseDesignPath, printoutLastUpdated, designParameters);
	  }
		      
	  // (neu-)compilieren 
	  if(new File(pathToJrxmlFile).isFile()) {
		  return getMainReportFromJRXMLFile(pathToJrxmlFile, pathToJasperFile, templateLocation,
			  baseDesignPath, printoutLastUpdated, designParameters);
	  } 
	  
	  return null;
  }
  
  private static JasperReport getMainReportFromJRXMLFile(String templateFile, 
		  String newReportName,
		  String templateLocation, 
		  String baseDesignPath,
		  String printoutLastUpdated,
		  HashMap<String, Object> designParameters) throws JRException, ReportingException, SQLException {

       JasperDesign jasperDesign = JRXmlLoader.load(templateFile);
       modifyMainReportSubRepParameters(jasperDesign.getParameters(), designParameters, templateLocation, baseDesignPath, printoutLastUpdated);

       // TODO Ticket 0003041 (siehe ISSUE - Wieso benötigen die Reporte zweiter Ebene einen InputStream damit ihre Übersetzungen korrekt sind?
       return Utility.getTranslatedJasperReport(_connectionProvider,
     		           templateFile, newReportName, _language, baseDesignPath);
  }

  private static void modifyMainReportSubRepParameters(JRParameter[] newParameters,
		  HashMap<String, Object> designParameters,
		  String templateLocation, 
		  String baseDesignPath,
		  String printoutLastUpdated) throws JRException, ReportingException, SQLException {
       
       for (JRParameter curParam : newParameters) {
    	   
		 String tmpName = curParam.getName();
		 
		 if (tmpName.startsWith("SUBREP_")) {
			addNewSubReportToDesignParameters(tmpName, templateLocation, baseDesignPath, printoutLastUpdated, designParameters);
		 }
       }
  }
  
  private static void addNewSubReportToDesignParameters(String parameterName, 
		  String templateLocation, 
		  String baseDesignPath,
		  String printoutLastUpdated,
		  HashMap<String, Object> designParameters) throws JRException, ReportingException, SQLException {
	  
	  String subReportFileName = transformParameterNameToFileName(templateLocation, parameterName, printoutLastUpdated);

	  JasperReport jasperReportLines = compileSubReport(templateLocation,
				subReportFileName, baseDesignPath);

	  designParameters.put(parameterName, jasperReportLines);
  }

  private static String transformParameterNameToFileName(String templateLocation,
		  String parameterName,
		  String printoutLastUpdated) {
	  
      String jrxmlFile = Replace.replace(parameterName, "SUBREP_", "") + ".jrxml";
      String jasperFile = createJasperSubReportFileName(jrxmlFile);

      if(new File(templateLocation + jasperFile).isFile()) {
    	  return jasperFile; 
      }
	      
      return jrxmlFile;
  }

  private static JasperReport compileSubReport(String templateLocation, 
		  String subReportFileName,
		  String baseDesignPath) {
	  
	    JasperReport jasperReportLines = null;
	    try {

		  String newReportName = (templateLocation + "/" + subReportFileName).replaceAll("//", "/");

	      // TODO Ticket 0003041 (siehe ISSUE - Wieso benötigen die Reporte zweiter Ebene einen InputStream damit ihre Übersetzungen korrekt sind?=
	      jasperReportLines = Utility.getTranslatedJasperReport(_connectionProvider, newReportName,
	    		  _language, baseDesignPath);
	    } catch (final JRException e1) {
	      log4j.error(e1.getMessage());
	      e1.printStackTrace();
	    }
	    return jasperReportLines;
  }
  
  private static JasperReport getMainReportFromJasperFile(String templateFile,
		  String templateLocation, 
		  String baseDesignPathString,
		  String printoutLastUpdated,
		  HashMap<String, Object> designParameters) throws JRException, ReportingException, SQLException {
      

      JasperReport jasperReport = (JasperReport)JRLoader.loadObjectFromFile(templateFile);
      modifyMainReportSubRepParameters(jasperReport.getParameters(), designParameters, templateLocation, baseDesignPathString, printoutLastUpdated);

      return jasperReport;
  }
}
