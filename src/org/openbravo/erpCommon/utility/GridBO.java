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

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.design.JasperDesign;

import net.sf.jasperreports.engine.export.JRCsvExporter;

import net.sf.jasperreports.engine.export.JRXlsExporter;

import net.sf.jasperreports.engine.xml.JRXmlLoader;

import org.apache.log4j.Logger;

class GridBO {
  private static Logger log4j = Logger.getLogger("org.openbravo.erpCommon.utility.GridBO");

  @SuppressWarnings("deprecation")
  public static void createHTMLReport(InputStream reportFile, GridReportVO gridReportVO,
      String path, String fileName) throws JRException, IOException {
    gridReportVO.setPagination(false);
    JasperPrint jasperPrint = createJasperPrint(reportFile, gridReportVO,true);
    net.sf.jasperreports.engine.export.JRHtmlExporter exporter = new net.sf.jasperreports.engine.export.JRHtmlExporter();
    Map<net.sf.jasperreports.engine.JRExporterParameter, Object> p = new HashMap<net.sf.jasperreports.engine.JRExporterParameter, Object>();
//    p.put(JRHtmlExporterParameter.JASPER_PRINT, jasperPrint);
//    p.put(JRHtmlExporterParameter.IS_USING_IMAGES_TO_ALIGN, Boolean.FALSE);
//    p.put(JRHtmlExporterParameter.OUTPUT_FILE_NAME, path + "/" + fileName);
    exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.JASPER_PRINT, jasperPrint);
    exporter.setParameter(net.sf.jasperreports.engine.export.JRHtmlExporterParameter.IS_USING_IMAGES_TO_ALIGN, Boolean.FALSE);
    exporter.setParameter(net.sf.jasperreports.engine.export.JRHtmlExporterParameter.OUTPUT_FILE_NAME, path + "/" + fileName);
    //exporter.setParameters(p);
    exporter.exportReport();

    
    
  }

  private static JasperDesign createJasperDesign(InputStream reportFile, GridReportVO gridReportVO, Boolean withfooter)
      throws JRException {
    JasperDesign jasperDesign = JRXmlLoader.load(reportFile);
    if (log4j.isDebugEnabled())
      log4j.debug("Create JasperDesign");
    ReportDesignBO designBO = new ReportDesignBO(jasperDesign, gridReportVO,withfooter);
    designBO.define();
    if (log4j.isDebugEnabled())
      log4j.debug("JasperDesign created, pageWidth: " + jasperDesign.getPageWidth()
          + " left margin: " + jasperDesign.getLeftMargin() + " right margin: "
          + jasperDesign.getRightMargin());
    return jasperDesign;
  }

  private static JasperPrint createJasperPrint(InputStream reportFile, GridReportVO gridReportVO, Boolean withfooter)
      throws JRException, IOException {
    JasperDesign jasperDesign = createJasperDesign(reportFile, gridReportVO,withfooter);
    JasperReport jasperReport = JasperCompileManager.compileReport(jasperDesign);
    Map<String, Object> parameters = new HashMap<String, Object>();
    parameters.put("BaseDir", gridReportVO.getContext());
    parameters.put("IS_IGNORE_PAGINATION", gridReportVO.getPagination());

    JasperPrint jasperPrint = JasperFillManager
        .fillReport(jasperReport, parameters, new JRFieldProviderDataSource(gridReportVO
            .getFieldProvider(), gridReportVO.getDateFormat()));
    return jasperPrint;
  }

  public static void createPDFReport(InputStream reportFile, GridReportVO gridReportVO,
      String path, String fileName) throws JRException, IOException {
    gridReportVO.setPagination(false);
    JasperPrint jasperPrint = createJasperPrint(reportFile, gridReportVO,true);
    JasperExportManager.exportReportToPdfFile(jasperPrint, path + "/" + fileName);
  }
  @SuppressWarnings("deprecation")
  public static void createXLSReport(InputStream reportFile, GridReportVO gridReportVO,
      String path, String fileName) throws JRException, IOException {
    gridReportVO.setPagination(true);
    JasperPrint jasperPrint = createJasperPrint(reportFile, gridReportVO,true);
    net.sf.jasperreports.engine.export.JExcelApiExporter exporter = new net.sf.jasperreports.engine.export.JExcelApiExporter();
//    Map<JRExporterParameter, Object> p = new HashMap<JRExporterParameter, Object>();
//
////    p.put(JRExporterParameter.JASPER_PRINT, jasperPrint);
////   p.put(JRExporterParameter.OUTPUT_FILE_NAME, path + "/" + fileName);
////   p.put(JExcelApiExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
////    p.put(JExcelApiExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
////    p.put(JExcelApiExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
    exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.JASPER_PRINT, jasperPrint);
   exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.OUTPUT_FILE_NAME, path + "/" + fileName);
    exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
   exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
    exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
//   exporter.setParameters(p);
    exporter.exportReport();
  }
  @SuppressWarnings("deprecation")
  public static void createCSVReport(InputStream reportFile, GridReportVO gridReportVO,
      String path, String fileName) throws JRException, IOException {
    gridReportVO.setPagination(true);
    JasperPrint jasperPrint = createJasperPrint(reportFile, gridReportVO,false);
    JRCsvExporter exporter = new JRCsvExporter();
    Map<net.sf.jasperreports.engine.JRExporterParameter, Object> p = new HashMap<net.sf.jasperreports.engine.JRExporterParameter, Object>();

    p.put(net.sf.jasperreports.engine.JRExporterParameter.JASPER_PRINT, jasperPrint);
    p.put(net.sf.jasperreports.engine.JRExporterParameter.OUTPUT_FILE_NAME, path + "/" + fileName);
    exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.JASPER_PRINT, jasperPrint);
    exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.OUTPUT_FILE_NAME, path + "/" + fileName);
   // exporter.setParameters(p);
    exporter.exportReport();
  }

 

}
