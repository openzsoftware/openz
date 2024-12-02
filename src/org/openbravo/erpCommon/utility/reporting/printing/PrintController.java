/*
 ***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
 */
package org.openbravo.erpCommon.utility.reporting.printing;


import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Vector;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;
import javax.mail.Address;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.transform.TransformerException;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.export.JRXlsExporter;
import net.sf.jasperreports.export.OutputStreamExporterOutput;
import net.sf.jasperreports.export.SimpleExporterInput;
import net.sf.jasperreports.export.SimpleOutputStreamExporterOutput;
import net.sf.jasperreports.export.SimpleXlsReportConfiguration;

import org.apache.commons.fileupload.FileItem;
import org.apache.pdfbox.exceptions.COSVisitorException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.mustangproject.ZUGFeRD.ZUGFeRDExporter;
import org.openbravo.base.exception.OBException;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.data.UtilSql;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.businessUtility.TabAttachmentsData;
import org.openbravo.erpCommon.utility.ComboTableData;
import org.openbravo.erpCommon.utility.poc.EmailManager;
import org.openbravo.erpCommon.utility.poc.EmailType;
import org.openbravo.erpCommon.utility.poc.PocException;
import org.openbravo.erpCommon.utility.reporting.DocumentType;
import org.openbravo.erpCommon.utility.reporting.EInvoice;
import org.openbravo.erpCommon.utility.reporting.EmailDefinitionData;
import org.openbravo.erpCommon.utility.reporting.Report;
import org.openbravo.erpCommon.utility.reporting.ReportManager;
import org.openbravo.erpCommon.utility.reporting.ReportingException;
import org.openbravo.erpCommon.utility.reporting.TemplateData;
import org.openbravo.erpCommon.utility.reporting.TemplateInfo;
import org.openbravo.erpCommon.utility.reporting.Report.OutputTypeEnum;
import org.openbravo.erpCommon.utility.reporting.TemplateInfo.EmailDefinition;
import org.openbravo.exception.NoConnectionAvailableException;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;

import com.lowagie.text.Document;
import com.lowagie.text.pdf.PdfCopy;
import com.lowagie.text.pdf.PdfImportedPage;
import com.lowagie.text.pdf.PdfReader;

import org.openz.view.*;
import org.openz.view.templates.ConfigurePopup;
import org.openz.util.FileUtils;

@SuppressWarnings("serial")
public class PrintController extends HttpSecureAppServlet {
  private final Map<String, TemplateData[]> differentDocTypes = new HashMap<String, TemplateData[]>();
//  private PocData[] pocData;
  private boolean multiReports = false;
  private boolean archivedReports = false;
  private String firstlang;
  
  @Override
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  @Override
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    throw new ServletException("No direct Calling of PrintController possible!");

  }

  @SuppressWarnings("unchecked")
  protected
 void post(HttpServletRequest request, HttpServletResponse response, VariablesSecureApp vars,
      DocumentType documentType, String sessionValuePrefix, String strDocumentId, FieldProvider[] dataSet)
      throws IOException, ServletException {

    Map<String, Report> reports;

    // Checks are maintained in this way for mulithread safety
    HashMap<String, Boolean> checks = new HashMap<String, Boolean>();
    checks.put("moreThanOneCustomer", Boolean.FALSE);
    checks.put("moreThanOnesalesRep", Boolean.FALSE);
    String documentIds[] = null;
    PocData[] pocData = null;
    String requestdoctype=documentType.getDoctype();
    if (dataSet== null){
    pocData = getContactDetails(documentType, strDocumentId, false);
    } else      {
      pocData= new PocData[dataSet.length];
      for (int i=0;i<pocData.length; i++) {
        pocData[i]= new PocData();
        pocData[i].documentId=dataSet[i].getField("documentId");
        pocData[i].docstatus=dataSet[i].getField("docstatus");
        pocData[i].ourreference=dataSet[i].getField("ourreference");
        pocData[i].yourreference=dataSet[i].getField("yourreference");
        pocData[i].salesrepUserId=dataSet[i].getField("salesrepUserId");
        pocData[i].salesrepEmail=dataSet[i].getField("salesrepEmail");
        pocData[i].salesrepName=dataSet[i].getField("salesrepName");
        pocData[i].bpartnerId=dataSet[i].getField("bpartnerId");
        pocData[i].bpartnerName=dataSet[i].getField("bpartnerName");
        pocData[i].contactUserId=dataSet[i].getField("contactUserId");
        pocData[i].contactEmail=dataSet[i].getField("contactEmail");
        pocData[i].contactName=dataSet[i].getField("contactName");
        pocData[i].adUserId=dataSet[i].getField("adUserId");
        pocData[i].userEmail=dataSet[i].getField("userEmail");
        pocData[i].userName=dataSet[i].getField("userName");
        pocData[i].reportLocation=dataSet[i].getField("reportLocation");
      }
    }
    if (log4j.isDebugEnabled())
      log4j.debug("strDocumentId: " + strDocumentId);
    // normalize the string of ids to a comma separated list
    strDocumentId = strDocumentId.replaceAll("\\(|\\)|'", "");
    if (strDocumentId.length() == 0)
      throw new ServletException(Utility.messageBD(this, "NoDocument", vars.getLanguage()));
    
    documentIds = strDocumentId.split(",");

    if (log4j.isDebugEnabled())
      log4j.debug("Number of documents selected: " + documentIds.length);

    multiReports = (documentIds.length > 1);
    reports = (Map<String, Report>) vars.getSessionObject(sessionValuePrefix + ".Documents");
    if (reports!=null)
      reports=null;
    // SZ: Get the selected Languages
    //TODO: Implement EMail Option with gui engine - fields are not in convention
    String secondlang="";
    if (vars.commandIn("EMAIL")) {
      firstlang= vars.getStringParameter("inpFirstLanguage");
      secondlang= vars.getStringParameter("inpSecondLanguage");
    }
    else{
      firstlang= vars.getStringParameter("inpfirstlanguage");
      secondlang= vars.getStringParameter("inpsecondlanguage");
    }
    secondlang=secondlang.equals("") ? firstlang : secondlang;
    final ReportManager reportManager = new ReportManager(this, globalParameters.strFTPDirectory,
        strReplaceWithFull, globalParameters.strBaseDesignPath,
        globalParameters.strDefaultDesignPath, globalParameters.prefix, multiReports,firstlang,secondlang,documentType);

    
    
    if (vars.commandIn("PRINT")||vars.commandIn("EMAIL")||vars.commandIn("ARCHIVE")||request.getServletPath().toLowerCase().indexOf("print.html") == -1)
    if (reports==null){
      // Initialize Reports and put em in session.
      reports = new HashMap<String, Report>();
      for (int index = 0; index < documentIds.length; index++) {
        final String documentId = documentIds[index];
        if (log4j.isDebugEnabled())
          log4j.debug("Processing document with id: " + documentId);
  
         // final Report report = new Report(this, documentType, documentId, vars.getLanguage(),
         //     "default", multiReports, OutputTypeEnum.DEFAULT);
          OutputTypeEnum outType=vars.commandIn("EMAIL") ? OutputTypeEnum.EMAIL :  vars.commandIn("PRINT") ? OutputTypeEnum.PRINT : vars.commandIn("ARCHIVE") ? OutputTypeEnum.PRINT : OutputTypeEnum.EMAIL;
          
          final Report report;
          report= buildReport(response, vars, documentId, reportManager,
              documentType, outType);
          final String isConfig = EmailData.isEmailConfigured(this, vars.getClient(), report
              .getOrgId());
  
          if (request.getServletPath().toLowerCase().indexOf("print.html") == -1) {
            if ("N".equals(isConfig)) {
              final OBError on = new OBError();
              on.setMessage(Utility.messageBD(this, "No EMail Server defined: Please go to client "
                  + "configuration to complete the email configuration", vars.getLanguage()));
              on.setTitle(Utility
                  .messageBD(this, "Email Configuration Error", vars.getLanguage()));
              on.setType("Error");
              final String tabId = vars.getSessionValue("inpTabId");
              vars.getStringParameter("tab");
              vars.setMessage(tabId, on);
              vars.getRequestGlobalVariable("inpTabId", "AttributeSetInstance.tabId");
              printPageClosePopUpAndRefreshParent(response, vars);
              throw new ServletException("Configuration Error no sender defined");
            }
            // if there is only one document type id the user should be
            // able to choose between different templates
          }
          reports.put(documentId, report);
          // check the different doc typeId's if all the selected
          // doc's
          // has the same doc typeId the template selector should
          // appear
          if (!differentDocTypes.containsKey(report.getDocTypeId())) {
            differentDocTypes.put(report.getDocTypeId(), report.getTemplate());
          }
  
      }
  
      vars.setSessionObject(sessionValuePrefix + ".Documents", reports);
    }
    
    if (vars.commandIn("PRINT")) {
      archivedReports = false;
      // Order documents by Document No.
      if (multiReports)
        documentIds = orderByDocumentNo(documentType, documentIds);

      /*
       * PRINT option will print directly to the UI for a single report. For multiple reports the
       * documents will each be saved individually and the concatenated in the same manner as the
       * saved reports. After concatenating the reports they will be deleted.
       */
      Report report = null;
      JasperPrint jasperPrint = null;
      Collection<JasperPrint> jrPrintReports = new ArrayList<JasperPrint>();
      final Collection<Report> savedReports = new ArrayList<Report>();
      for (int i = 0; i < documentIds.length; i++) {
        String documentId = documentIds[i];
        report = buildReport(response, vars, documentId, reportManager, documentType,
            Report.OutputTypeEnum.PRINT);
        try {
          jasperPrint = reportManager.processReport(report, vars,"DRAFT");
          jrPrintReports.add(jasperPrint);
        } catch (final ReportingException e) {
          advisePopUp(request, response, "Report processing failed",
              "Unable to process report selection");
          log4j.error(e.getMessage());
          e.getStackTrace();
        }
        savedReports.add(report);
        if (multiReports) {
          reportManager.saveTempReport(report, vars, "DRAFT");
        }
      }
      printReports(request,response, jrPrintReports, savedReports,requestdoctype);
    } else if (vars.commandIn("ARCHIVE")) {
      // Order documents by Document No.
      if (multiReports)
        documentIds = orderByDocumentNo(documentType, documentIds);

      /*
       * ARCHIVE will save each report individually and then print the reports in a single printable
       * (concatenated) format.
       */
      archivedReports = true;
      Report report = null;
      JasperPrint jasperPrint = null;
      Collection<JasperPrint> jrPrintReports = new ArrayList<JasperPrint>();
      final Collection<Report> savedReports = new ArrayList<Report>();
      for (int index = 0; index < documentIds.length; index++) {
        String documentId = documentIds[index];
        report = buildReport(response, vars, documentId, reportManager, documentType,
            OutputTypeEnum.ARCHIVE);
        buildReport(response, vars, documentId, reports, reportManager);
        try {
            jasperPrint = reportManager.processReport(report, vars,"");
            jrPrintReports.add(jasperPrint);
        } catch (final ReportingException e) {
          log4j.error(e);
        }
        reportManager.saveTempReport(report, vars);
        savedReports.add(report);
      }
      printReports(request,response, jrPrintReports, savedReports,requestdoctype);
    } else {
      if (vars.commandIn("DEFAULT")) {
        // Fix 
        vars.setSessionValue("PRINTDOCUMENTS", strDocumentId);
        vars.setSessionObject(sessionValuePrefix + ".Documents", null);

        if (request.getServletPath().toLowerCase().indexOf("print.html") != -1)
          createPrintOptionsPage(request, response, vars, documentType,
              getComaSeparatedString(documentIds), reports);
        else {
			if (dataSet==null){
			  createEmailOptionsPage(request, response, vars, documentType,
			      getComaSeparatedString(documentIds), reports, checks,null);
			}  createEmailOptionsPage(request, response, vars, documentType,
			      getComaSeparatedString(documentIds), reports, checks, dataSet);
        }

          
        

      } else if (vars.commandIn("ADD")||vars.commandIn("CHANGE")) {
        if (request.getServletPath().toLowerCase().indexOf("print.html") != -1)
          createPrintOptionsPage(request, response, vars, documentType,
              getComaSeparatedString(documentIds), reports);
        else {
          final boolean showList = true;
          if (dataSet==null){
            createEmailOptionsPage(request, response, vars, documentType,
                getComaSeparatedString(documentIds), reports, checks,null);
          }else{
            createEmailOptionsPage(request, response, vars, documentType,
                getComaSeparatedString(documentIds), reports, checks, dataSet);
          }}}

       else if (vars.commandIn("DEL")) {
        final String documentToDelete = vars.getStringParameter("idToDelete");
        final Vector<Object> vector = (Vector<Object>) request.getSession(false).getAttribute("files");
        request.getSession(false).setAttribute("files", vector);

        seekAndDestroy(vector, documentToDelete);
        if (dataSet==null){
          createEmailOptionsPage(request, response, vars, documentType,
              getComaSeparatedString(documentIds), reports, checks,null);
        }else{
          createEmailOptionsPage(request, response, vars, documentType,
              getComaSeparatedString(documentIds), reports, checks, dataSet);
        }

      } else if (vars.commandIn("EMAIL")) {
        int nrOfEmailsSend = 0;
        for (final PocData documentData : pocData) {
          getEnvironentInformation(pocData, checks);
          final String documentId = documentData.documentId;
          if (log4j.isDebugEnabled())
            log4j.debug("Processing document with id: " + documentId);

          final Report report = buildReport(response, vars, documentId, reportManager,
              documentType, OutputTypeEnum.EMAIL);
          
          
          if (report == null)
            throw new ServletException(Utility.messageBD(this, "NoDataReport", vars.getLanguage())
                + documentId);
          // Check if the document is not in status 'draft'
          if (!report.isDraft()) {
            // Check if the report is already attached
            if (!report.isAttached()) {
              // get the Id of the entities table, this is used to
              // store the file as an OB attachment
              final String tableId = ToolsData.getTableId(this, report.getDocumentType()
                  .getTableName());
              try {
                reportManager.createAttachmentForReport(this, report, tableId, vars);
              } catch (final ReportingException exception) {
                  throw new ServletException(exception);
              }
              // Implementing eInvoices
              // X-Rechnung - EMail Button
              if (report.getdefaultTemplate().equals("38D81133009C4C9CB8B378EF4EA31DE3") || report.getdefaultTemplate().equals("C6D78C6A518F420B897DB1E933133EF5")) {
              	EInvoice xrech= new EInvoice();
              	xrech.PrepareXInvoiceEmail(report, response, this,globalParameters.strFTPDirectory);
              }	
            } else {
              if (log4j.isDebugEnabled())
                log4j.debug("Document is not attached.");
            }
            final String senderAddress = EmailData.getSenderAddress(this, vars.getClient(), report
                .getOrgId());
            sendDocumentEmail(report, vars, (Vector<Object>) request.getSession(false).getAttribute(
                "files"), documentData, senderAddress, checks);
            nrOfEmailsSend++;
          }
        }
        request.getSession(false).removeAttribute("files");
        createPrintStatusPage(response, vars, nrOfEmailsSend);
      }

      pageError(response);
    }
  }

  private void printReports(HttpServletRequest request,HttpServletResponse response, Collection<JasperPrint> jrPrintReports,
      Collection<Report> reports, String DocFormat) {
    ServletOutputStream os = null;
    String filename = "";
    final VariablesSecureApp vars = new VariablesSecureApp(request);
   
    try {
      
      os = response.getOutputStream();
      response.setContentType("application/pdf"); // default pdf

      if (!multiReports && !archivedReports) {
        for (Iterator<Report> iterator = reports.iterator(); iterator.hasNext();) {
          Report report = iterator.next();
          filename = report.getFilename();

          // get name of template to check for excel substring
          TemplateData templates[] = report.getTemplate();
          TemplateInfo usedTemplate = report.getTemplateInfo();
          for(TemplateData td : templates) {
              if(td.cPocDoctypeTemplateId.equals(usedTemplate.getPocDocTypeId())) {
                  if(td.name.contains("EXCEL")) {
                      filename = filename.replace(".pdf", ".xls");
                      response.setContentType("application/xls");
                  }
              }
          }
        }

        response.setHeader("Content-disposition", "attachment" + "; filename=" + filename);
        for (Iterator<JasperPrint> iterator = jrPrintReports.iterator(); iterator.hasNext();) {
          JasperPrint jasperPrint = (JasperPrint) iterator.next();
          
          if(filename.contains(".xls")) {
              JRXlsExporter exporter = new JRXlsExporter();
              exporter.setExporterInput(new SimpleExporterInput(jasperPrint));
              exporter.setExporterOutput(new SimpleOutputStreamExporterOutput(os));
              SimpleXlsReportConfiguration configuration = new SimpleXlsReportConfiguration();
              configuration.setOnePagePerSheet(false);
              configuration.setDetectCellType(true);
              configuration.setRemoveEmptySpaceBetweenRows(true);
              configuration.setWhitePageBackground(false);
              configuration.setIgnoreCellBackground(true);
              String[] sheetNames = new String[1];
              sheetNames[0] = "1"; // only one sheet
              configuration.setSheetNames(sheetNames);
              exporter.setConfiguration(configuration);
              exporter.exportReport();
              log4j.info("xls "+filename);
          } else {
              JasperExportManager.exportReportToPdfStream(jasperPrint, os);
              log4j.info("pdf "+filename);
          }
        }
      } else {
          concatReport(reports.toArray(new Report[] {}), jrPrintReports.toArray(new JasperPrint[] {}), response);
      }
    } catch (IOException e) {
      log4j.error(e.getMessage());
    } catch (Exception e) {
      e.printStackTrace();
      try {
    	  response.reset();
    	  this.bdErrorGeneralPopUp(request, response, "ERROR", e.getMessage());
       } catch (Exception ign) {}
    }  finally {
      try {
        os.close();
        String Doc= reports.iterator().next().getFilename();
        response.flushBuffer();
        
        // automatically add Zugferd to all outgoing invoices
        if (DocFormat.equals("INVOICE") && vars.commandIn("ARCHIVE")){
        
        PDDocument doc = PDDocument.load(globalParameters.strFTPDirectory+"/tmp/"+Doc);
        ZUGFeRDExporter ze = new ZUGFeRDExporter();
        log4j.info("Converting to PDF/A-3u");
        try {
          ze.PDFmakeA3compliant(doc, "My Application",
          System.getProperty("user.name"), true);
        } catch (TransformerException e) {
          // TODO Auto-generated catch block
          e.printStackTrace();
        }
        //System.out.println("Attaching ZUGFeRD-Data");
        log4j.info("Attaching ZUGFeRD-Data");
        String ownZUGFeRDXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + 
            "<rsm:CrossIndustryDocument xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:rsm=\"urn:ferd:CrossIndustryDocument:invoice:1p0\" xmlns:ram=\"urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:12\" xmlns:udt=\"urn:un:unece:uncefact:data:standard:UnqualifiedDataType:15\">\n" + 
            "        <rsm:SpecifiedExchangedDocumentContext>\n" + 
            "                <ram:TestIndicator><udt:Indicator>true</udt:Indicator></ram:TestIndicator>\n" + 
            "                <ram:GuidelineSpecifiedDocumentContextParameter>\n" + 
            "                        <ram:ID>urn:ferd:CrossIndustryDocument:invoice:1p0:comfort</ram:ID>\n" + 
            "                </ram:GuidelineSpecifiedDocumentContextParameter>\n" + 
            "        </rsm:SpecifiedExchangedDocumentContext>\n" + 
            "        <rsm:HeaderExchangedDocument>\n" + 
            "                <ram:ID>RE-20151008/504</ram:ID>\n" + 
            "                <ram:Name>RECHNUNG</ram:Name>\n" + 
            "                <ram:TypeCode>380</ram:TypeCode>\n" + 
            "                <ram:IssueDateTime><udt:DateTimeString format=\"102\">20151008</udt:DateTimeString></ram:IssueDateTime>\n" + 
            "<ram:IncludedNote>\n" + 
            "                <ram:Content>\n" + 
            "Bei Spiel GmbH\n" + 
            "Ecke 12\n" + 
            "12345 Stadthausen\n" + 
            "Geschäftsführer: Max Mustermann         </ram:Content>\n" + 
            "<ram:SubjectCode>REG</ram:SubjectCode>\n" + 
            "</ram:IncludedNote>\n" + 
            "        </rsm:HeaderExchangedDocument>\n" + 
            "        <rsm:SpecifiedSupplyChainTradeTransaction>\n" + 
            "                <ram:ApplicableSupplyChainTradeAgreement>\n" + 
            "                        <ram:SellerTradeParty>\n" + 
            "                                <ram:Name>Bei Spiel GmbH</ram:Name>\n" + 
            "                                <ram:PostalTradeAddress>\n" + 
            "                                        <ram:PostcodeCode>12345</ram:PostcodeCode>\n" + 
            "                                        <ram:LineOne>Ecke 12</ram:LineOne>\n" + 
            "                                        <ram:CityName>Stadthausen</ram:CityName>\n" + 
            "                                        <ram:CountryID>DE</ram:CountryID>\n" + 
            "                                </ram:PostalTradeAddress>\n" + 
            "                                <ram:SpecifiedTaxRegistration>\n" + 
            "                                        <ram:ID schemeID=\"FC\">22/815/0815/4</ram:ID>\n" + 
            "                                </ram:SpecifiedTaxRegistration>\n" + 
            "                                <ram:SpecifiedTaxRegistration>\n" + 
            "                                        <ram:ID schemeID=\"VA\">DE136695976</ram:ID>\n" + 
            "                                </ram:SpecifiedTaxRegistration>\n" + 
            "                        </ram:SellerTradeParty>\n" + 
            "                        <ram:BuyerTradeParty>\n" + 
            "                                <ram:Name>Theodor Est</ram:Name>\n" + 
            "                                <ram:PostalTradeAddress>\n" + 
            "                                        <ram:PostcodeCode>88802</ram:PostcodeCode>\n" + 
            "                                        <ram:LineOne>Bahnstr. 42</ram:LineOne>\n" + 
            "                                        <ram:CityName>Spielkreis</ram:CityName>\n" + 
            "                                        <ram:CountryID>DE</ram:CountryID>\n" + 
            "                                </ram:PostalTradeAddress>\n" + 
            "                                <ram:SpecifiedTaxRegistration>\n" + 
            "                                        <ram:ID schemeID=\"VA\">DE999999999</ram:ID>\n" + 
            "                                </ram:SpecifiedTaxRegistration>\n" + 
            "                        </ram:BuyerTradeParty>\n" + 
            "                </ram:ApplicableSupplyChainTradeAgreement>\n" + 
            "                <ram:ApplicableSupplyChainTradeDelivery>\n" + 
            "                        <ram:ActualDeliverySupplyChainEvent>\n" + 
            "                                <ram:OccurrenceDateTime><udt:DateTimeString format=\"102\">20151007</udt:DateTimeString></ram:OccurrenceDateTime>\n" + 
            "                        </ram:ActualDeliverySupplyChainEvent>\n" + 
            "                </ram:ApplicableSupplyChainTradeDelivery>\n" + 
            "                <ram:ApplicableSupplyChainTradeSettlement>\n" + 
            "                        <ram:PaymentReference>RE-20151008/504</ram:PaymentReference>\n" + 
            "                        <ram:InvoiceCurrencyCode>EUR</ram:InvoiceCurrencyCode>\n" + 
            "                        <ram:SpecifiedTradeSettlementPaymentMeans>\n" + 
            "                                <ram:TypeCode>42</ram:TypeCode>\n" + 
            "                                <ram:Information>Überweisung</ram:Information>\n" + 
            "                                <ram:PayeePartyCreditorFinancialAccount>\n" + 
            "                                        <ram:IBANID>DE88 2008 0000 0970 3757 00</ram:IBANID>\n" + 
            "                                </ram:PayeePartyCreditorFinancialAccount>\n" + 
            "                                <ram:PayeeSpecifiedCreditorFinancialInstitution>\n" + 
            "                                        <ram:BICID>COBADEFXXX</ram:BICID>\n" + 
            "                                        <ram:Name>Commerzbank</ram:Name>\n" + 
            "                                </ram:PayeeSpecifiedCreditorFinancialInstitution>\n" + 
            "                        </ram:SpecifiedTradeSettlementPaymentMeans>\n" + 
            "                        <ram:ApplicableTradeTax>\n" + 
            "                                <ram:CalculatedAmount currencyID=\"EUR\">11.20</ram:CalculatedAmount>\n" + 
            "                                <ram:TypeCode>VAT</ram:TypeCode>\n" + 
            "                                <ram:BasisAmount currencyID=\"EUR\">160.00</ram:BasisAmount>\n" + 
            "                                <ram:CategoryCode>S</ram:CategoryCode>\n" + 
            "                                <ram:ApplicablePercent>7.00</ram:ApplicablePercent>\n" + 
            "                        </ram:ApplicableTradeTax>\n" + 
            "                        <ram:ApplicableTradeTax>\n" + 
            "                                <ram:CalculatedAmount currencyID=\"EUR\">63.84</ram:CalculatedAmount>\n" + 
            "                                <ram:TypeCode>VAT</ram:TypeCode>\n" + 
            "                                <ram:BasisAmount currencyID=\"EUR\">336.00</ram:BasisAmount>\n" + 
            "                                <ram:CategoryCode>S</ram:CategoryCode>\n" + 
            "                                <ram:ApplicablePercent>19.00</ram:ApplicablePercent>\n" + 
            "                        </ram:ApplicableTradeTax>\n" + 
            "                        <ram:SpecifiedTradePaymentTerms>\n" + 
            "                                <ram:Description>Zahlbar ohne Abzug bis 29.10.2015</ram:Description>\n" + 
            "                                <ram:DueDateDateTime><udt:DateTimeString format=\"102\">20151029</udt:DateTimeString></ram:DueDateDateTime>\n" + 
            "                        </ram:SpecifiedTradePaymentTerms>\n" + 
            "                        <ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                                <ram:LineTotalAmount currencyID=\"EUR\">496.00</ram:LineTotalAmount>\n" + 
            "                                <ram:ChargeTotalAmount currencyID=\"EUR\">0.00</ram:ChargeTotalAmount>\n" + 
            "                                <ram:AllowanceTotalAmount currencyID=\"EUR\">0.00</ram:AllowanceTotalAmount>\n" + 
            "                                <ram:TaxBasisTotalAmount currencyID=\"EUR\">496.00</ram:TaxBasisTotalAmount>\n" + 
            "                                <ram:TaxTotalAmount currencyID=\"EUR\">75.04</ram:TaxTotalAmount>\n" + 
            "                                <ram:GrandTotalAmount currencyID=\"EUR\">571.04</ram:GrandTotalAmount>\n" + 
            "                                <ram:DuePayableAmount currencyID=\"EUR\">571.04</ram:DuePayableAmount>\n" + 
            "                        </ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                </ram:ApplicableSupplyChainTradeSettlement>\n" + 
            "                <ram:IncludedSupplyChainTradeLineItem>\n" + 
            "                        <ram:AssociatedDocumentLineDocument>\n" + 
            "                                <ram:LineID>1</ram:LineID>\n" + 
            "                        </ram:AssociatedDocumentLineDocument>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeAgreement>\n" + 
            "                                <ram:GrossPriceProductTradePrice>\n" + 
            "                                        <ram:ChargeAmount currencyID=\"EUR\">160.0000</ram:ChargeAmount>\n" + 
            "                                        <ram:BasisQuantity unitCode=\"HUR\">1.0000</ram:BasisQuantity>\n" + 
            "                                </ram:GrossPriceProductTradePrice>\n" + 
            "                                <ram:NetPriceProductTradePrice>\n" + 
            "                                        <ram:ChargeAmount currencyID=\"EUR\">160.0000</ram:ChargeAmount>\n" + 
            "                                        <ram:BasisQuantity unitCode=\"HUR\">1.0000</ram:BasisQuantity>\n" + 
            "                                </ram:NetPriceProductTradePrice>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeAgreement>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeDelivery>\n" + 
            "                                <ram:BilledQuantity unitCode=\"HUR\">1.0000</ram:BilledQuantity>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeDelivery>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeSettlement>\n" + 
            "                                <ram:ApplicableTradeTax>\n" + 
            "                                        <ram:TypeCode>VAT</ram:TypeCode>\n" + 
            "                                        <ram:CategoryCode>S</ram:CategoryCode>\n" + 
            "                                        <ram:ApplicablePercent>7.00</ram:ApplicablePercent>\n" + 
            "                                </ram:ApplicableTradeTax>\n" + 
            "                                <ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                                        <ram:LineTotalAmount currencyID=\"EUR\">160.00</ram:LineTotalAmount>\n" + 
            "                                </ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeSettlement>\n" + 
            "                        <ram:SpecifiedTradeProduct>\n" + 
            "                                <ram:Name>Künstlerische Gestaltung (Stunde)</ram:Name>\n" + 
            "                                <ram:Description></ram:Description>\n" + 
            "                        </ram:SpecifiedTradeProduct>\n" + 
            "                </ram:IncludedSupplyChainTradeLineItem>\n" + 
            "                <ram:IncludedSupplyChainTradeLineItem>\n" + 
            "                        <ram:AssociatedDocumentLineDocument>\n" + 
            "                                <ram:LineID>2</ram:LineID>\n" + 
            "                        </ram:AssociatedDocumentLineDocument>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeAgreement>\n" + 
            "                                <ram:GrossPriceProductTradePrice>\n" + 
            "                                        <ram:ChargeAmount currencyID=\"EUR\">0.7900</ram:ChargeAmount>\n" + 
            "                                        <ram:BasisQuantity unitCode=\"C62\">1.0000</ram:BasisQuantity>\n" + 
            "                                </ram:GrossPriceProductTradePrice>\n" + 
            "                                <ram:NetPriceProductTradePrice>\n" + 
            "                                        <ram:ChargeAmount currencyID=\"EUR\">0.7900</ram:ChargeAmount>\n" + 
            "                                        <ram:BasisQuantity unitCode=\"C62\">1.0000</ram:BasisQuantity>\n" + 
            "                                </ram:NetPriceProductTradePrice>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeAgreement>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeDelivery>\n" + 
            "                                <ram:BilledQuantity unitCode=\"C62\">400.0000</ram:BilledQuantity>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeDelivery>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeSettlement>\n" + 
            "                                <ram:ApplicableTradeTax>\n" + 
            "                                        <ram:TypeCode>VAT</ram:TypeCode>\n" + 
            "                                        <ram:CategoryCode>S</ram:CategoryCode>\n" + 
            "                                        <ram:ApplicablePercent>19.00</ram:ApplicablePercent>\n" + 
            "                                </ram:ApplicableTradeTax>\n" + 
            "                                <ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                                        <ram:LineTotalAmount currencyID=\"EUR\">316.00</ram:LineTotalAmount>\n" + 
            "                                </ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeSettlement>\n" + 
            "                        <ram:SpecifiedTradeProduct>\n" + 
            "                                <ram:Name>Luftballon</ram:Name>\n" + 
            "                                <ram:Description></ram:Description>\n" + 
            "                        </ram:SpecifiedTradeProduct>\n" + 
            "                </ram:IncludedSupplyChainTradeLineItem>\n" + 
            "                <ram:IncludedSupplyChainTradeLineItem>\n" + 
            "                        <ram:AssociatedDocumentLineDocument>\n" + 
            "                                <ram:LineID>3</ram:LineID>\n" + 
            "                        </ram:AssociatedDocumentLineDocument>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeAgreement>\n" + 
            "                                <ram:GrossPriceProductTradePrice>\n" + 
            "                                        <ram:ChargeAmount currencyID=\"EUR\">0.1000</ram:ChargeAmount>\n" + 
            "                                        <ram:BasisQuantity unitCode=\"LTR\">1.0000</ram:BasisQuantity>\n" + 
            "                                </ram:GrossPriceProductTradePrice>\n" + 
            "                                <ram:NetPriceProductTradePrice>\n" + 
            "                                        <ram:ChargeAmount currencyID=\"EUR\">0.1000</ram:ChargeAmount>\n" + 
            "                                        <ram:BasisQuantity unitCode=\"LTR\">1.0000</ram:BasisQuantity>\n" + 
            "                                </ram:NetPriceProductTradePrice>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeAgreement>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeDelivery>\n" + 
            "                                <ram:BilledQuantity unitCode=\"LTR\">200.0000</ram:BilledQuantity>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeDelivery>\n" + 
            "                        <ram:SpecifiedSupplyChainTradeSettlement>\n" + 
            "                                <ram:ApplicableTradeTax>\n" + 
            "                                        <ram:TypeCode>VAT</ram:TypeCode>\n" + 
            "                                        <ram:CategoryCode>S</ram:CategoryCode>\n" + 
            "                                        <ram:ApplicablePercent>19.00</ram:ApplicablePercent>\n" + 
            "                                </ram:ApplicableTradeTax>\n" + 
            "                                <ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                                        <ram:LineTotalAmount currencyID=\"EUR\">20.00</ram:LineTotalAmount>\n" + 
            "                                </ram:SpecifiedTradeSettlementMonetarySummation>\n" + 
            "                        </ram:SpecifiedSupplyChainTradeSettlement>\n" + 
            "                        <ram:SpecifiedTradeProduct>\n" + 
            "                                <ram:Name>Heiße Luft pro Liter</ram:Name>\n" + 
            "                                <ram:Description></ram:Description>\n" + 
            "                        </ram:SpecifiedTradeProduct>\n" + 
            "                </ram:IncludedSupplyChainTradeLineItem>\n" + 
            "        </rsm:SpecifiedSupplyChainTradeTransaction>\n" + 
            "</rsm:CrossIndustryDocument>";
        ze.setZUGFeRDXMLData(ownZUGFeRDXML.getBytes());
        ze.PDFattachZugferdFile(doc, null);
        log4j.info("Writing ZUGFeRD-PDF");
        doc.save(globalParameters.strFTPDirectory+"/tmp/"+Doc);
        }   } catch (IOException e) {
        log4j.error(e.getMessage(), e);
      } catch (COSVisitorException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
    }
  }

  /*
   * This method is base on code originally created by Mark Thompson (Concatenate.java) and
   * distributed under the following conditions.
   * 
   * $Id: Concatenate.java 3373 2008-05-12 16:21:24Z xlv $
   * 
   * This code is free software. It may only be copied or modified if you include the following
   * copyright notice:
   * 
   * This class by Mark Thompson. Copyright (c) 2002 Mark Thompson.
   * 
   * This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
   * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   */
  private void concatReport(Report[] reports, JasperPrint[] jasperPrints, HttpServletResponse response) throws Exception{
      int pageOffset = 0;
      // ArrayList master = new ArrayList();
      int f = 0;
      String filename = "";
      Report outFile = null;
      if (reports.length == 1)
        filename = reports[0].getFilename();
      Document document = null;
      PdfCopy writer = null;
      while (f < reports.length) {
        if (filename == null || filename.equals("")) {
          outFile = reports[f];
          if (multiReports) {
            filename = outFile.getTemplateInfo().getReportFilename();
            filename = filename.replaceAll("@our_ref@", "");
            filename = filename.replaceAll("@cus_ref@", "");
            filename = filename.replaceAll(" ", "_");
            filename = filename.replaceAll("-", "");
            filename = filename + ".pdf";
          } else {
            filename = outFile.getFilename();
          }
        }
        // get name of template to check for excel substring
        TemplateData templates[] = reports[0].getTemplate();
        TemplateInfo usedTemplate = reports[0].getTemplateInfo();
        for(TemplateData td : templates) {
            if(td.cPocDoctypeTemplateId.equals(usedTemplate.getPocDocTypeId())) {
                if(td.name.contains("EXCEL")) {
                    filename = filename.replace(".pdf", ".xls");
                    response.setContentType("application/xls");
                }
            }
        }
        // Implementing eInvoices
        // X-Rechnung - Print Button
        if (archivedReports && (reports[0].getdefaultTemplate().equals("38D81133009C4C9CB8B378EF4EA31DE3") || reports[0].getdefaultTemplate().equals("C6D78C6A518F420B897DB1E933133EF5"))) {
        	if (multiReports) 
        		throw new Exception("Unable to print multiple Documents when using X-Invoice ");
        	EInvoice xrech= new EInvoice();
        	xrech.ReturnXInvoice(reports[0], response, this,globalParameters.strFTPDirectory);
        	return;
        }	
        response.setHeader("Content-disposition", "attachment" + "; filename=" + filename);

        if(filename.contains(".xls")) {
            JRXlsExporter exporter = new JRXlsExporter();
            // all exports in on xls-file, multiple sheets
            exporter.setExporterInput(SimpleExporterInput.getInstance(Arrays.asList(jasperPrints)));
            exporter.setExporterOutput(new SimpleOutputStreamExporterOutput(response.getOutputStream()));
            SimpleXlsReportConfiguration configuration = new SimpleXlsReportConfiguration();
            configuration.setOnePagePerSheet(false);
            configuration.setDetectCellType(true);
            configuration.setRemoveEmptySpaceBetweenRows(true);
            configuration.setWhitePageBackground(false);
            configuration.setIgnoreCellBackground(true);
            String[] sheetNames = new String[jasperPrints.length];
            for(int i = 0; i < jasperPrints.length; i++) {
                sheetNames[i] = i+1 + "";
            }
            configuration.setSheetNames(sheetNames);
            exporter.setConfiguration(configuration);
            exporter.exportReport();
            break; //break loop, everything already printed
        }else {
            // we create a reader for a certain document
            PdfReader reader = new PdfReader(reports[f].getTargetLocation());
            reader.consolidateNamedDestinations();
            // we retrieve the total number of pages
            int n = reader.getNumberOfPages();
            pageOffset += n;

            if (f == 0) {
              // step 1: creation of a document-object
              document = new Document(reader.getPageSizeWithRotation(1));
              // step 2: we create a writer that listens to the document
              writer = new PdfCopy(document, response.getOutputStream());
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
            if (reports[f].isDeleteable()) {
              File file = new File(reports[f].getTargetLocation());
              if (file.exists() && !file.isDirectory()) {
                file.delete();
              }
            }
        }
        f++;
      }
      if(document!=null) {
          document.close();
      }
  }

  private Report buildReport(HttpServletResponse response, VariablesSecureApp vars,
      String strDocumentId, final ReportManager reportManager, DocumentType documentType,
      OutputTypeEnum outputType) throws  ServletException {
    Report report = null;
    if (strDocumentId != null) {
      strDocumentId = strDocumentId.replaceAll("\\(|\\)|'", "");
    }
    String template="";
    
    template=vars.getStringParameter("inpdoctype");
    if (template.equals("")){
      template=vars.getStringParameter("inptemplates");
    }
      
    try {
      if (template.equals("")) {
        report = new Report(this, documentType, strDocumentId, firstlang, "",
            multiReports, outputType);
          template=PrintControllerData.GetDefaultDoctypeTempate(this, report.getDocTypeId(), vars.getOrg());
      }
      report = new Report(this, documentType, strDocumentId, firstlang, template,
          multiReports, outputType);
    } catch (final ReportingException e) {
      log4j.error(e);
      throw new ServletException(e.getMessage());
    } 

    reportManager.setTargetDirectory(report);
    return report;
  }

  private void buildReport(HttpServletResponse response, VariablesSecureApp vars,
      String strDocumentId, Map<String, Report> reports, final ReportManager reportManager)
      throws ServletException, IOException {
    final String documentId = vars.getStringParameter("inpDocumentId");
    if (strDocumentId != null)
      strDocumentId = strDocumentId.replaceAll("\\(|\\)|'", "");
    final Report report = reports.get(strDocumentId);
    if (report == null)
      throw new ServletException(Utility.messageBD(this, "NoDataReport", vars.getLanguage())
          + documentId);
    // Check if the document is not in status 'draft'
    if (!report.isDraft() && !report.isAttached() && vars.commandIn("ARCHIVE")) {
      // TODO: Move the table Id retrieval into the DocumentType
      // getTableId method!
      // get the Id of the entities table, this is used to store the
      // file as an OB attachment
      final String tableId = ToolsData.getTableId(this, report.getDocumentType().getTableName());

      if (log4j.isDebugEnabled())
        log4j.debug("Table " + report.getDocumentType().getTableName() + " has table id: "
            + tableId);
      // Save the report as a attachment because it is being
      // transferred to the user
      try {
        reportManager.createAttachmentForReport(this, report, tableId, vars);
      } catch (final ReportingException exception) {
        throw new ServletException(exception);
      }
    } else {
      if (log4j.isDebugEnabled())
        log4j.debug("Document is not attached.");
    }
  }

  
  /**
   * 
   * @param vector
   * @param documentToDelete
   */
  private void seekAndDestroy(Vector<Object> vector, String documentToDelete) {
    for (int i = 0; i < vector.size(); i++) {
      final AttachContent content = (AttachContent) vector.get(i);
      if (content.id.equals(documentToDelete)) {
        vector.remove(i);
        break;
      }
    }

  }

  PocData[] getContactDetails(DocumentType documentType, String strDocumentId, boolean getAllDunrunInvoices)
      throws ServletException {
    if (documentType.getDoctype().equals("ORDER"))
      return PocData.getContactDetailsForOrders(this, strDocumentId);
    if (documentType.getDoctype().equals("INVOICE"))
      return PocData.getContactDetailsForInvoices(this, strDocumentId);
    if (documentType.getDoctype().equals("SHIPMENT"))
      return PocData.getContactDetailsForShipments(this, strDocumentId);
    if (documentType.getDoctype().equals("DUNRUN")) {
    	Vector<String> drIds=new Vector();
    	Vector<String> InvIds=new Vector();
    	String invIdList ="";
        String strSql = "";
        if(getAllDunrunInvoices) { // only for error message, get all invoices
            strSql =   "select dunrun_getallinvoices(DUNRUN_HISTORY_ID) as invoice_id,dunrun_history_id as dunrun_history_id from  DUNRUN_HISTORY where DUNRUN_HISTORY_id in " + strDocumentId ;
        }else {
            strSql =   "select dunrun_getinvoice(DUNRUN_HISTORY_ID) as invoice_id,dunrun_history_id as dunrun_history_id from  DUNRUN_HISTORY where DUNRUN_HISTORY_id in " + strDocumentId ;
        }

        ResultSet result;
        PreparedStatement st = null;
        
        try {
            st = this.getPreparedStatement(strSql);   
            result = st.executeQuery();
            while(result.next()) {
            	if (!invIdList.isEmpty())
            		invIdList=invIdList+",";
            	invIdList=invIdList+ "'" + UtilSql.getValue(result, "invoice_id") +"'";
            	drIds.add(UtilSql.getValue(result, "dunrun_history_id"));
            	InvIds.add(UtilSql.getValue(result, "invoice_id"));
            }
            result.close();
            PocData[] PocDatatmp= PocData.getContactDetailsForInvoices(this, "(" + invIdList +")");
            for (int i=0;i<PocDatatmp.length;i++) {
            	PocDatatmp[i].cDoctypeId="965E1D712EF0413998793FA43695BCB1";
            	for (int j=0;j<PocDatatmp.length;j++) {
            		if (PocDatatmp[i].documentId.equals(InvIds.get(j)))
            			PocDatatmp[i].documentId=drIds.get(j);
            	}
            }
            return PocDatatmp;
            
        } catch(Exception e){
        	e.printStackTrace();
        } finally {
            try {
                this.releasePreparedStatement(st);
              } catch(Exception ignore){
                ignore.printStackTrace();
              }
        }
    }  
    return null;
  }

  void sendDocumentEmail(Report report, VariablesSecureApp vars, Vector<Object> object,
      PocData documentData, String senderAddess, HashMap<String, Boolean> checks)
      throws IOException, ServletException {
    final String documentId = report.getDocumentId();
    final String attachmentFileLocation = report.getTargetLocation();
    final String ourReference = report.getOurReference();
    final String cusReference = report.getCusReference();
    if (log4j.isDebugEnabled())
      log4j.debug("our document ref: " + ourReference);
    if (log4j.isDebugEnabled())
      log4j.debug("cus document ref: " + cusReference);
    // Also send it to the current user
    final PocData[] currentUserInfo = PocData.getContactDetailsForUser(this, vars.getUser());
    final String userName = currentUserInfo[0].userName;
    final String userEmail = currentUserInfo[0].userEmail;
    if (log4j.isDebugEnabled())
      log4j.debug("user name: " + userName);
    if (log4j.isDebugEnabled())
      log4j.debug("user email: " + userEmail);
    final String contactName = documentData.contactName;
    String contactEmail = null;
    String contactCCEmail = null;
    final String salesrepName = documentData.salesrepName;
    String salesrepEmail = null;
    String allAttachments ="Attachments: ";

    boolean moreThanOneCustomer = checks.get("moreThanOneCustomer").booleanValue();
    boolean moreThanOnesalesRep = checks.get("moreThanOnesalesRep").booleanValue();
    if (moreThanOneCustomer) {
      contactEmail = documentData.contactEmail;
      contactCCEmail = documentData.contactCcemail;
    } else {
      contactEmail = vars.getStringParameter("contactEmail");
      contactCCEmail = vars.getStringParameter("CCEmail");
    }

    if (moreThanOnesalesRep) {
      if (EmailDefinitionData.getCentalSenderEmail(this).isEmpty())
        salesrepEmail = documentData.salesrepEmail;
      else
        salesrepEmail = EmailDefinitionData.getCentalSenderEmail(this);
    } else {
      salesrepEmail = vars.getStringParameter("salesrepEmail");
    }
    String emailSubject = vars.getStringParameter("emailSubject");
    String emailBody = vars.getStringParameter("emailBody");

    if (log4j.isDebugEnabled())
      log4j.debug("sales rep name: " + salesrepName);
    if (log4j.isDebugEnabled())
      log4j.debug("sales rep email: " + salesrepEmail);
    if (log4j.isDebugEnabled())
      log4j.debug("recipient name: " + contactName);
    if (log4j.isDebugEnabled())
      log4j.debug("recipient email: " + contactEmail);

    // TODO: Move this to the beginning of the print handling and do nothing
    // if these conditions fail!!!)

    if ((salesrepEmail == null || salesrepEmail.length() == 0)) {
      throw new ServletException(Utility.messageBD(this, "NoSalesRepEmail", vars.getLanguage()));
    }

    if ((contactEmail == null || contactEmail.length() == 0)) {
      throw new ServletException(Utility.messageBD(this, "NoCustomerEmail", vars.getLanguage()));
    }

    // Replace special tags
    emailSubject = PrintControllerData.resolveSpecialTags(this, documentId, emailSubject);

    emailBody = PrintControllerData.resolveSpecialTags(this, documentId, emailBody);

    try {
      EmailManager mailman = new EmailManager(); 
      final Session session = mailman.newMailSession(this, vars.getClient(), report.getOrgId());

      final Message message = new MimeMessage(session);
      // SZ: Bugfix
      // Using salesrepEmail as from, senderAddess as BCC (Archive EMail)
      // senderAddess is retrieved from Global EMail configuration (Client Setup)
      Address[] address = new InternetAddress[1];
      address[0] = new InternetAddress(salesrepEmail);
      message.setReplyTo(address);
      message.setFrom(new InternetAddress(salesrepEmail));
      String[] tokens = contactEmail.split(";");
      for (int i = 0; i < tokens.length; i++) {
    	  message.addRecipient(Message.RecipientType.TO, new InternetAddress(tokens[i]));
      }
      if (!contactCCEmail.isEmpty()){
	      tokens = contactCCEmail.split(";");
	      for (int i = 0; i < tokens.length; i++) {
	    	  message.addRecipient(Message.RecipientType.CC, new InternetAddress(tokens[i]));
	      }
      }
      if (senderAddess!=null && !senderAddess.isEmpty())
    	  message.addRecipient(Message.RecipientType.BCC, new InternetAddress(senderAddess));

      // message.addRecipient(Message.RecipientType.BCC, new InternetAddress(salesrepEmail));

      if (userEmail != null && userEmail.length() > 0)
        message.addRecipient(Message.RecipientType.BCC, new InternetAddress(userEmail));

      message.setSubject(emailSubject);

      // Content consists of 2 parts, the message body and the attachment
      // We therefor use a multipart message
      final Multipart multipart = new MimeMultipart();

      // Create the message part
      MimeBodyPart messageBodyPart = new MimeBodyPart();
      messageBodyPart.setText(emailBody);
      multipart.addBodyPart(messageBodyPart);

      // Create the attachment part (Document)
      messageBodyPart = new MimeBodyPart();
      if (vars.getStringParameter("Document").equals("Y")||multiReports) {
	      //final DataSource source = new FileDataSource(attachmentFileLocation);
	      //messageBodyPart.setDataHandler(new DataHandler(source));
	      //messageBodyPart.setFileName(attachmentFileLocation.substring(attachmentFileLocation
	      //    .lastIndexOf("/") + 1));
	      //multipart.addBodyPart(messageBodyPart);
	      final File file = new File(attachmentFileLocation);
	      messageBodyPart.attachFile(file,"application/pdf",null);
	      multipart.addBodyPart(messageBodyPart);
	      allAttachments=allAttachments+report.getFilename() + ", ";
      }
      //
      // Add eventually Attachments of the EMail Template
      if (vars.getStringParameter("TemplateAttachments").equals("Y")) {
	      String template=vars.getStringParameter("inptemplates");
	      String lang=vars.getStringParameter("inpFirstLanguage");
	      EmailOptionsData[] eod=EmailOptionsData.selectAttachmentsByTemplate(this, template,lang);
	      for (int i=0; i< eod.length; i++) {
	    	  final File file = new File(globalParameters.strFTPDirectory + "/" +  eod[i].attachments);
	    	  messageBodyPart = new MimeBodyPart();
	          messageBodyPart.attachFile(file,eod[i].mimetype,null);
	          multipart.addBodyPart(messageBodyPart);
	          allAttachments=allAttachments+eod[i].document + ", ";
	      }
      }
      //
      // Add eventually available Attachments of the Current Document
      final String tableId = ToolsData.getTableId(this, report.getDocumentType().getTableName());
      EmailOptionsData[] userattch= EmailOptionsData.selectUserAddedAttachments(this, tableId,report.getDocumentId());
      if (userattch.length>0 && !multiReports) {
  		for (int i=0;i<userattch.length;i++) {
  			if (vars.getStringParameter(userattch[i].identifier).equals("Y")) {
  				messageBodyPart = new MimeBodyPart();
  				final File file = new File(globalParameters.strFTPDirectory + "/" + userattch[i].attachments);
  				messageBodyPart.attachFile(file,userattch[i].mimetype,null);
  	            multipart.addBodyPart(messageBodyPart);
  	            allAttachments=allAttachments+userattch[i].document + ", ";
  			}
  		}
  	  }
      //
      // Add aditional MANUAL attached documents
      if (object != null) {
        final Vector<Object> vector = (Vector<Object>) object;
        for (int i = 0; i < vector.size(); i++) {
          final AttachContent content = (AttachContent) vector.get(i);
          final File file = prepareFile(content,attachmentFileLocation.substring(0,attachmentFileLocation
              .lastIndexOf("/") + 1));
          messageBodyPart = new MimeBodyPart();
          messageBodyPart.attachFile(file);
          multipart.addBodyPart(messageBodyPart);
          allAttachments=allAttachments+content.fileName + ", ";
          Connection connn = null;
          try {
	          connn=this.getTransactionConnection();
	          TabAttachmentsData.insertta(connn, this, SequenceIdData.getUUID(), vars.getClient(), vars
	                  .getOrg(), vars.getUser(), tableId, report.getDocumentId(), "103",
	                  "Attached by EMail ", content.fileName);
	          this.releaseCommitConnection(connn);
          } catch (final Exception e) {throw new PocException(e.getMessage());
          } finally {
              this.releaseRollbackConnection(connn);
          }
        }
      }

      message.setContent(multipart);
      
      //Attach EMail-Text to Document
      String receivers,subject;
      receivers="To: " + contactEmail + ", CC: " +contactCCEmail + ", Sender: " + salesrepEmail + "\r\n";
      subject="Btr: " + emailSubject + "\r\n";
      String attch=allAttachments +  "\r\n\r\n" + receivers + subject + "\r\n" + emailBody;
      Connection connn = null;
      try {
    	  String targetLocation=report.getTargetDirectory().getPath();
    	  String fname=org.openz.util.FileUtils.string2File(targetLocation, "EmailText.txt", attch,false);
          connn=this.getTransactionConnection();
          TabAttachmentsData.insert(connn, this, SequenceIdData.getUUID(), vars.getClient(), vars
                  .getOrg(), vars.getUser(), tableId, report.getDocumentId(), "100",
                  "Sent EMail", fname);
          this.releaseCommitConnection(connn);
      } catch (final Exception e) {throw new PocException(e.getMessage());
      } finally {
          this.releaseRollbackConnection(connn);
      }

      // Send the email
      Transport.send(message);

    } catch (final PocException exception) {
      log4j.error(exception);
      throw new ServletException(exception);
    } catch (final AddressException exception) {
      log4j.error(exception);
      throw new ServletException(exception);
    } catch (final SQLException exception) {
        log4j.error(exception);
        throw new ServletException(exception);
      }catch (final MessagingException exception) {
      log4j.error(exception);
      throw new ServletException("problems with the SMTP server configuration: "
          + exception.getMessage(), exception);
    }
  }

  void createPrintOptionsPage(HttpServletRequest request, HttpServletResponse response,
      VariablesSecureApp vars, DocumentType documentType, String strDocumentId,
      Map<String, Report> reports) throws IOException, ServletException {
    
    try {
      String actualdoctype="";
      if (documentType.getDefaultDoctypeName() != null) 
        actualdoctype=PrintControllerData.getDocTypeByName(this, documentType.getDefaultDoctypeName());
      else
        actualdoctype=PrintControllerData.getDocTypeId(myPool, documentType.getTableName(), documentType.getTableName()+"_id", strDocumentId.substring(2, 34) );
      vars.setSessionValue("#C_DOCTYPE_ID", actualdoctype);

      // set default language in print popup to bpartner language
      String defaultLanguage = "";
      defaultLanguage = PrintControllerData.getLangOfBpartner(myPool, documentType.getTableName(), documentType.getTableName()+"_id", strDocumentId.substring(2, 34) );

      if(defaultLanguage == null || defaultLanguage.isEmpty()) {
          defaultLanguage = vars.getLanguage();
      }
      vars.setSessionValue(this.getClass().getName() + "|FIRSTLANGUAGE",defaultLanguage);
      // Show Option for Multi-Language
      if (PrintControllerData.IsMultilanguage(myPool, vars.getClient()).equals("Y") && documentType.isMultiLanguage())
        vars.setSessionValue(this.getClass().getName() + "|ISMULTILANGUAGE", "Y");
      // Build the GUI
      Scripthelper script= new Scripthelper();
      Formhelper fh=new Formhelper();
      String strSkeleton = ConfigurePopup.doConfigure(this,vars,script,"PrintDocument", "btnPrintOnly");
      script.addHiddenfield("inpadOrgId", vars.getOrg());
      script.enableshortcuts("POPUP");
      script.setPopupSize("600", "400");
      String strStandardFG=fh.prepareFieldgroup(this, vars, script, "PrintOptionsFG", null,false);
      String strAdditionalFG="";
      // Additional Fieldgroup is Loaded in the Document via the calling class (e.g. PrintEmployees)
      if (documentType.getAdditionalFieldgroup()!=null)
        strAdditionalFG=fh.prepareFieldgroup(this, vars, script, documentType.getAdditionalFieldgroup(), null,false);
      //Generating html source
      String strOutput=Replace.replace(strSkeleton, "@CONTENT@",strStandardFG + strAdditionalFG); 
      strOutput = script.doScript(strOutput, "",this,vars);
      response.setContentType("text/html; charset=UTF-8");
      PrintWriter out = response.getWriter();
      out.println(strOutput);
      out.close();
    }
    catch (Exception e) { 
      log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
      e.printStackTrace();
       throw new ServletException(e);

     }  
    
  }

  void createEmailOptionsPage(HttpServletRequest request, HttpServletResponse response,
      VariablesSecureApp vars, DocumentType documentType, String strDocumentId,
      Map<String, Report> reports, HashMap<String, Boolean> checks, FieldProvider[] dataSet) throws IOException,
      ServletException {
    XmlDocument xmlDocument = null;
    PocData[] pocData;
    if (dataSet== null){
      pocData = getContactDetails(documentType, strDocumentId, false);
      } else      {
        pocData= new PocData[dataSet.length];
        for (int i=0;i<pocData.length; i++) {
          pocData[i]= new PocData();
          pocData[i].documentId=dataSet[i].getField("documentId");
          pocData[i].docstatus=dataSet[i].getField("docstatus");
          pocData[i].ourreference=dataSet[i].getField("ourreference");
          pocData[i].yourreference=dataSet[i].getField("yourreference");
          pocData[i].salesrepUserId=dataSet[i].getField("salesrepUserId");
          pocData[i].salesrepEmail=dataSet[i].getField("salesrepEmail");
          pocData[i].salesrepName=dataSet[i].getField("salesrepName");
          pocData[i].bpartnerId=dataSet[i].getField("bpartnerId");
          pocData[i].bpartnerName=dataSet[i].getField("bpartnerName");
          pocData[i].contactUserId=dataSet[i].getField("contactUserId");
          pocData[i].contactEmail=dataSet[i].getField("contactEmail");
          pocData[i].contactName=dataSet[i].getField("contactName");
          pocData[i].adUserId=dataSet[i].getField("adUserId");
          pocData[i].userEmail=dataSet[i].getField("userEmail");
          pocData[i].userName=dataSet[i].getField("userName");
          pocData[i].reportLocation=dataSet[i].getField("reportLocation");
        }
      }
    @SuppressWarnings("unchecked")
    Vector<java.lang.Object> vector = (Vector<java.lang.Object>) request.getSession(false).getAttribute(
        "files");
    // Load Template
    final String[] hiddenTags = getHiddenTags(pocData, vector, vars, checks);
    if (hiddenTags != null) {
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/utility/reporting/printing/EmailOptions", hiddenTags)
          .createXmlDocument();
    } else {
      xmlDocument = xmlEngine.readXmlTemplate(
          "org/openbravo/erpCommon/utility/reporting/printing/EmailOptions").createXmlDocument();
    }
   // SZ: Show Option for Multi-Language
    if (PrintControllerData.IsMultilanguage(myPool, vars.getClient()).equals("Y"))
      xmlDocument.setParameter("multiLanguageID","visibility:visible");
    // SZ: Fill Language Options
    ComboTableData comboTableData = null;
    try {
        // Load Reference AD_Language system
        xmlDocument.setParameter("FirstLanguage", vars.getLanguage());
        comboTableData = new ComboTableData(vars, this, "TABLE", "", "AD_Language system", "", "('0')","('0')",0);
        Utility.fillSQLParameters(this, vars, null, comboTableData, "PrintOptions", vars.getLanguage());
        xmlDocument.setData("reportFirstLanguage", "liststructure", comboTableData.select(false));
        //xmlDocument.setParameter("SecondLanguage", vars.getLanguage());
        comboTableData = new ComboTableData(vars, this, "TABLE", "", "AD_Language system", "", "('0')","('0')",0);
        Utility.fillSQLParameters(this, vars, null, comboTableData, "PrintOptions", "");
        xmlDocument.setData("reportSecondLanguage", "liststructure", comboTableData.select(false));
    } catch (Exception ex) {
      throw new ServletException(ex);
    }

    xmlDocument.setParameter("strDocumentId", strDocumentId);

    boolean isTheFirstEntry = false;
    if (vector == null) {
      vector = new Vector<java.lang.Object>(0);
      isTheFirstEntry = Boolean.valueOf(true);
    }

    final AttachContent file = new AttachContent();
    if (vars.getMultiFile("inpFile") != null && !vars.getMultiFile("inpFile").getName().equals("")) {
      final AttachContent content = new AttachContent();
      final FileItem file1 = vars.getMultiFile("inpFile");
      content.setFileName(file1.getName());
      content.setFileItem(file1);
      content.setId(file1.getName());
      content.visible = "hidden";
      if (vars.getStringParameter("inpArchive") == "Y") {
        content.setSelected("true");
      }
      vector.addElement(content);
      request.getSession(false).setAttribute("files", vector);

    }

    if ("yes".equals(vars.getStringParameter("closed"))) {
      xmlDocument.setParameter("closed", "yes");
      request.getSession(false).removeAttribute("files");
    }

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\r\n");
    xmlDocument.setParameter("language", vars.getLanguage());
    xmlDocument.setParameter("theme", vars.getTheme());

    EmailOptionsData[] eodata=EmailOptionsData.select(myPool, vars.getLanguage(), pocData[0].cDoctypeId) ;
    if (eodata.length==0) {
      final OBError on = new OBError();
      on.setMessage(Utility.messageBD(this, "There is no email configuration configured", vars
          .getLanguage()));
      on.setTitle(Utility.messageBD(this, "Info", vars.getLanguage()));
      on.setType("info");
      final String tabId = vars.getSessionValue("inpTabId");
      vars.getStringParameter("tab");
      vars.setMessage(tabId, on);
      vars.getRequestGlobalVariable("inpTabId", "AttributeSetInstance.tabId");
      printPageClosePopUpAndRefreshParent(response, vars);
    }

    // Get additional document information
    String draftDocumentIds = "";
    AttachContent attachedContent = new AttachContent();
    final boolean onlyOneAttachedDoc = onlyOneAttachedDocs(reports);
    final Map<String, PocData> customerMap = new HashMap<String, PocData>();
    final Map<String, PocData> salesRepMap = new HashMap<String, PocData>();
    final Vector<Object> cloneVector = new Vector<Object>();
    boolean allTheDocsCompleted = true;
    for (final PocData documentData : pocData) {
      // Map used to count the different users

      final String customer = documentData.contactEmail;
      getEnvironentInformation(pocData, checks);
      if (checks.get("moreThanOneDoc")) {
        if (customer == null || customer.length() == 0) {
          final OBError on = new OBError();
          // There is at least one document with no connected email. The customer has no email on record and there is no contact with an email entered for the document.
          // get all affected documents
          // Format: Customer: Docnumber, Contact
          String affectedDocs = "";
          int counter = 0;
          // identical to pocData UNLESS it is a dunrun
          for(final PocData innerErrorLoop : getContactDetails(documentType, strDocumentId, true)) {
              if(innerErrorLoop.contactEmail == null || innerErrorLoop.contactEmail.length() == 0) {
                  if(counter == 0) {
                      affectedDocs = "</br>" + innerErrorLoop.bpartnerName + ": " + innerErrorLoop.ourreference + ", " + (innerErrorLoop.contactName.isEmpty() ? "-" : innerErrorLoop.contactName);
                  }else if(counter == 10) {
                      // print maximum of 10 documents
                      affectedDocs = affectedDocs + "</br>" + "...";
                      break;
                  }else {
                      affectedDocs = affectedDocs + "</br>" + innerErrorLoop.bpartnerName + ": " + innerErrorLoop.ourreference + ", " + (innerErrorLoop.contactName.isEmpty() ? "-" : innerErrorLoop.contactName);
                  }
                  counter++;
              }
          }
          on.setMessage(Utility.messageBD(this, "documentNoContactOrNoEmail", vars.getLanguage()) + affectedDocs);
          on.setTitle(Utility.messageBD(this, "Info", vars.getLanguage()));
          on.setType("info");
          final String tabId = vars.getSessionValue("inpTabId");
          vars.getStringParameter("tab");
          vars.setMessage(tabId, on);
          vars.getRequestGlobalVariable("inpTabId", "AttributeSetInstance.tabId");
          printPageClosePopUpAndRefreshParent(response, vars);
        }
      }
      // Central EMail sender Adresss
      if (!EmailDefinitionData.getCentalSenderEmail(myPool).isEmpty())
        documentData.salesrepEmail=EmailDefinitionData.getCentalSenderEmail(myPool);
      
      if (!customerMap.containsKey(customer)) {
        customerMap.put(customer, documentData);
      }

      final String salesRep = documentData.salesrepName;
      

      boolean moreThanOnesalesRep = checks.get("moreThanOnesalesRep").booleanValue();
      if (moreThanOnesalesRep) {
          // only throw error, if no sender email is found
          if (documentData.salesrepEmail == null || documentData.salesrepEmail.equals("")) {
              final OBError on = new OBError();

              // no sales rep entered
              if (salesRep == null || salesRep.length() == 0) {
                  on.setMessage(Utility.messageBD(this,
                          "There is at least one document with no sender set. "
                                  + "Furthermore there is no central sender Email set.",
                          vars.getLanguage()));

              // no email entered for sales rep
              } else {
                  on.setMessage(Utility.messageBD(this,
                          "There is at least one document with no sender Email set (" + salesRep + "). "
                                  + "Furthermore there is no central sender Email set.",
                          vars.getLanguage()));
              }

              on.setTitle(Utility.messageBD(this, "Info", vars.getLanguage()));
              on.setType("info");
              final String tabId = vars.getSessionValue("inpTabId");
              vars.getStringParameter("tab");
              vars.setMessage(tabId, on);
              vars.getRequestGlobalVariable("inpTabId", "AttributeSetInstance.tabId");
              printPageClosePopUpAndRefreshParent(response, vars);
          }
      }
        
      if (!salesRepMap.containsKey(salesRep)) {
        salesRepMap.put(salesRep, documentData);
      }

      Report report = reports.get(documentData.documentId);
      
        
      // All ids of documents in draft are passed to the web client

      if (report.isDraft()) {
        if (draftDocumentIds.length() > 0)
          draftDocumentIds += ",";
        draftDocumentIds += report.getDocumentId();
        allTheDocsCompleted = false;
      }

      // Fill the report location
      final String reportFilename = report.getContextSubFolder() + report.getFilename();
      documentData.reportLocation = request.getContextPath() + "/" + reportFilename
          + "?documentId=" + documentData.documentId;
      if (log4j.isDebugEnabled())
        log4j.debug(" Filling report location with: " + documentData.reportLocation);

      if (onlyOneAttachedDoc) {
        attachedContent.setDocName(report.getFilename());
        attachedContent.setVisible("checkbox");
        attachedContent.setId("Document");
        cloneVector.add(attachedContent);
      }

    }
    if (!allTheDocsCompleted) {
      final OBError on = new OBError();
      on.setMessage(Utility.messageBD(this,
          "DocsNotCompleted", vars
              .getLanguage()));
      on.setTitle(Utility.messageBD(this, "info", vars.getLanguage()));
      on.setType("info");
      final String tabId = vars.getSessionValue("inpTabId");
      vars.getStringParameter("tab");
      vars.setMessage(tabId, on);
      vars.getRequestGlobalVariable("inpTabId", "AttributeSetInstance.tabId");
      printPageClosePopUpAndRefreshParent(response, vars);
    }

    final int numberOfCustomers = customerMap.size();
    final int numberOfSalesReps = salesRepMap.size();

    if (!onlyOneAttachedDoc && isTheFirstEntry) {
      if (numberOfCustomers > 1) {
        attachedContent.setDocName(String.valueOf(reports.size() + " Documents to "
            + String.valueOf(numberOfCustomers) + " Customers"));
        attachedContent.setVisible("checkbox");

      } else {
        attachedContent.setDocName(String.valueOf(reports.size() + " Documents"));
        attachedContent.setVisible("checkbox");

      }
      cloneVector.add(attachedContent);
    }
    if (isTheFirstEntry) {
	    String temp;
	    String lang;
	    if (vars.commandIn("DEFAULT")) {
	    	temp=reports.get(pocData[0].documentId).getdefaultTemplate();
	    	lang=vars.getLanguage();
	    } else {
	  	  temp=  vars.getStringParameter("inptemplates");
	  	  lang=  vars.getStringParameter("inpFirstLanguage");
	    }
	    if (! EmailOptionsData.getAttachmentsByTemplate(this, temp,lang).isEmpty()) {
	      attachedContent = new AttachContent();
	  	  attachedContent.setDocName(EmailOptionsData.getAttachmentsByTemplate(this, temp,lang));
	  	  attachedContent.setVisible("checkbox");
	  	  attachedContent.setId("TemplateAttachments");
	  	  cloneVector.add(attachedContent);
	    }  
    }
    // Collect all Attachments From Upload by User and Present them to Send with Email
    if (!multiReports) {
    	final String tableId = ToolsData.getTableId(this, documentType.getTableName());
    	EmailOptionsData[] userattch= EmailOptionsData.selectUserAddedAttachments(this, tableId,strDocumentId.replace("('","").replace("')", ""));
    	if (userattch.length>0) {
    		for (int i=0;i<userattch.length;i++) {
    			attachedContent = new AttachContent();
    			attachedContent.setDocName(userattch[i].document);
    			attachedContent.setVisible("checkbox");
    			attachedContent.setId(userattch[i].identifier);
    		  	cloneVector.add(attachedContent);
    		}
    	}
    }
    final AttachContent[] data = new AttachContent[vector.size()];
    final AttachContent[] data2 = new AttachContent[cloneVector.size()];
    if (cloneVector.size() >= 1) { // Has more than 1 element
      vector.copyInto(data);
      cloneVector.copyInto(data2);
      xmlDocument.setData("structure2", data2);
      xmlDocument.setData("structure1", data);
    }
    if (pocData.length >= 1) {
        xmlDocument.setData("reportEmail", "liststructure", reports.get((pocData[0].documentId))
            .getTemplate());
    }
    if (log4j.isDebugEnabled())
      log4j.debug("Documents still in draft: " + draftDocumentIds);
    xmlDocument.setParameter("draftDocumentIds", draftDocumentIds);

    if (vars.commandIn("CHANGE")) {
    	String lang=vars.getStringParameter("inpFirstLanguage");
    	if (lang.isEmpty())
    		lang=vars.getLanguage();
    	String template=vars.getStringParameter("inptemplates");
    	EmailOptionsData[] eod=EmailOptionsData.selectByTemplate(this, lang, template);
    	if (eod.length>0) {
	    	xmlDocument.setParameter("emailSubject", eod[0].subject);
	    	xmlDocument.setParameter("emailBody", eod[0].emailbody);
    	}
    	xmlDocument.setParameter("contactEmail", vars.getStringParameter("contactEmail"));
        xmlDocument.setParameter("CCEmail", vars.getStringParameter("CCEmail"));
        xmlDocument.setParameter("salesrepEmail", vars.getStringParameter("salesrepEmail"));
        xmlDocument.setParameter("templates",template);
        xmlDocument.setParameter("FirstLanguage", vars.getStringParameter("inpFirstLanguage"));
  
    } else if (vars.commandIn("ADD") || vars.commandIn("DEL")) {
      final String emailSubject = vars.getStringParameter("emailSubject");
      final String emailBody = vars.getStringParameter("emailBody");
      xmlDocument.setParameter("emailSubject", emailSubject);
      xmlDocument.setParameter("emailBody", emailBody);
      xmlDocument.setParameter("contactEmail", vars.getStringParameter("contactEmail"));
      xmlDocument.setParameter("CCEmail", vars.getStringParameter("CCEmail"));
      xmlDocument.setParameter("salesrepEmail", vars.getStringParameter("salesrepEmail"));
      xmlDocument.setParameter("templates",vars.getStringParameter("inptemplates"));
      xmlDocument.setParameter("FirstLanguage", vars.getStringParameter("inpFirstLanguage"));
    } else {
      xmlDocument.setParameter("emailSubject", eodata[0].subject);
      xmlDocument.setParameter("contactEmail",pocData[0].contactEmail);
      xmlDocument.setParameter("CCEmail", pocData[0].contactCcemail);
      xmlDocument.setParameter("salesrepEmail", pocData[0].salesrepEmail);
      xmlDocument.setParameter("emailBody", eodata[0].emailbody);
      String t=reports.get(pocData[0].documentId).getdefaultTemplate();
      xmlDocument.setParameter("templates",reports.get(pocData[0].documentId).getdefaultTemplate());
    }
    
    xmlDocument.setParameter("inpArchive", vars.getStringParameter("inpArchive"));
    xmlDocument.setParameter("contactName", pocData[0].contactName);
    xmlDocument.setParameter("salesrepName", pocData[0].salesrepName);
    xmlDocument.setParameter("inpArchive", vars.getStringParameter("inpArchive"));
    if (numberOfCustomers>1)
    	xmlDocument.setParameter("CCEmail", "");
    xmlDocument.setParameter("multCusCount", String.valueOf(numberOfCustomers));
    xmlDocument.setParameter("multSalesRepCount", String.valueOf(numberOfSalesReps));
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    
    String output = xmlDocument.print();
    output = output.replaceAll("@specialTagsPlaceholder@", EmailOptionsData.getSpecialTagsDescriptionTable(this, firstlang.equals("") ? vars.getLanguage() : firstlang));
    out.println(output);
    out.close();
  }

 

  private void getEnvironentInformation(PocData[] pocData, HashMap<String, Boolean> checks) {
    final Map<String, PocData> customerMap = new HashMap<String, PocData>();
    final Map<String, PocData> salesRepMap = new HashMap<String, PocData>();
    int docCounter = 0;
    checks.put("moreThanOneDoc", false);
    for (final PocData documentData : pocData) {
      // Map used to count the different users
      docCounter++;
      final String customer = documentData.contactName;
      final String salesRep = documentData.salesrepName;
      if (!customerMap.containsKey(customer)) {
        customerMap.put(customer, documentData);
      }
      if (!salesRepMap.containsKey(salesRep)) {
        salesRepMap.put(salesRep, documentData);
      }
    }
    if (docCounter > 1) {
      checks.put("moreThanOneDoc", true);
    }
    boolean moreThanOneCustomer = (customerMap.size() > 1);
    boolean moreThanOnesalesRep = (salesRepMap.size() > 1);
    checks.put("moreThanOneCustomer", Boolean.valueOf(moreThanOneCustomer));
    checks.put("moreThanOnesalesRep", Boolean.valueOf(moreThanOnesalesRep));
  }

  /**
   * @author gmauleon
   * @param pocData
   * @param vars
   * @param vector
   * @return
   */
  private String[] getHiddenTags(PocData[] pocData, Vector<Object> vector, VariablesSecureApp vars,
      HashMap<String, Boolean> checks) throws ServletException{
    String[] discard;
    final Map<String, PocData> customerMap = new HashMap<String, PocData>();
    final Map<String, PocData> salesRepMap = new HashMap<String, PocData>();
    for (final PocData documentData : pocData) {
      // Map used to count the different users

      final String customer = documentData.contactEmail;
      final String salesRep = documentData.salesrepEmail;
      if (!customerMap.containsKey(customer)) {
        customerMap.put(customer, documentData);
      }
      if (!salesRepMap.containsKey(salesRep)) {
        salesRepMap.put(salesRep, documentData);
      }
    }
    boolean moreThanOneCustomer = (customerMap.size() > 1);
    boolean moreThanOnesalesRep = (salesRepMap.size() > 1);
    checks.put("moreThanOneCustomer", Boolean.valueOf(moreThanOneCustomer));
    checks.put("moreThanOnesalesRep", Boolean.valueOf(moreThanOnesalesRep));

    // check the number of customer and the number of
    // sales Rep. to choose one of the 3 possibilities
    // 1.- n customer n sales rep (hide both inputs)
    // 2.- n customers 1 sales rep (hide only first input)
    // 3.- Otherwise show both
    if (moreThanOneCustomer && moreThanOnesalesRep) {
      discard = new String[] { "customer", "salesRep","customercc" };
    } else if (moreThanOneCustomer) {
      discard = new String[] { "customer", "customercc","multSalesRep", "multSalesRepCount" };
    } else {
      discard = new String[] { "multipleCustomer" };
    }

    // check the templates
   // if (differentDocTypes.size() > 1) { // the templates selector shouldn't
      // appear
      /*
      if (discard == null) { // Its the only think to hide
        discard = new String[] { "discardSelect" };
      } else {
        final String[] discardAux = new String[discard.length + 1];
        for (int i = 0; i < discard.length; i++) {
          discardAux[0] = discard[0];
        }
        discardAux[discard.length] = "discardSelect";
        return discardAux;
      }
      */
     // throw new ServletException("@cannotusedifferentdoctypes4emeil@");
   // }
    if (vector == null && vars.getMultiFile("inpFile") == null) {
      if (discard == null) {
        discard = new String[] { "view" };
      } else {
        final String[] discardAux = new String[discard.length + 1];
        for (int i = 0; i < discard.length; i++) {
          discardAux[i] = discard[i];
        }
        discardAux[discard.length] = "view";
        return discardAux;
      }
    }
    return discard;
  }

  private boolean onlyOneAttachedDocs(Map<String, Report> reports) {
    if (reports.size() == 1) {
      return true;
    } else {
      return false;
    }

  }

  void createPrintStatusPage(HttpServletResponse response, VariablesSecureApp vars,
      int nrOfEmailsSend) throws IOException, ServletException {
    XmlDocument xmlDocument = null;
    xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/utility/reporting/printing/PrintStatus").createXmlDocument();
    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\r\n");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("language", vars.getLanguage());
    xmlDocument.setParameter("nrOfEmailsSend", "" + nrOfEmailsSend);

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();

    out.println(xmlDocument.print());
    out.close();
  }

  /**
   * 
   * @param documentIds
   * @return returns a comma separated and quoted string of documents id's. useful to sql querys
   */
  private String getComaSeparatedString(String[] documentIds) {
    String result = new String("(");
    for (int index = 0; index < documentIds.length; index++) {
      final String documentId = documentIds[index];
      if (index + 1 == documentIds.length) {
        result = result + "'" + documentId + "')";
      } else {
        result = result + "'" + documentId + "',";
      }

    }
    return result;
  }

  /**
   * @author gmauleon
   * @param content
   * @return
   * @throws ServletException
   */
  private File prepareFile(AttachContent content, String path) throws ServletException {
    try {
      File f = new File(path + "/" + content.getFileName());
      if (f.exists()) {
    	  final String dateOfPrint = Utility.formatDate(new Date(), "yyyy-MM-dd-HH:mm:ss");
    	  f = new File(path + "/" + dateOfPrint + "-" + content.getFileName());
      }
	  final InputStream inputStream = content.getFileItem().getInputStream();
	  final OutputStream out = new FileOutputStream(f);
	  final byte buf[] = new byte[1024];
	  int len;
	  while ((len = inputStream.read(buf)) > 0)
	        out.write(buf, 0, len);
	  out.close();
	  inputStream.close();
      return f;
    } catch (final Exception e) {
      throw new ServletException("Error trying to get the attached file", e);
    }

  }

  /**
   * Returns an array of document's ID ordered by Document No ASC
   * 
   * @param documentType
   * @param documentIds
   *          array of document's ID without order
   * @return List of ordered IDs
   * @throws ServletException
   */
  private String[] orderByDocumentNo(DocumentType documentType, String[] documentIds)
      throws ServletException {
    String strTable = documentType.getTableName();

    StringBuffer strIds = new StringBuffer();
    strIds.append("'");
    for (int i = 0; i < documentIds.length; i++) {
      if (i > 0) {
        strIds.append("', '");
      }
      strIds.append(documentIds[i]);
    }
    strIds.append("'");

    PrintControllerData[] printControllerData;
    String documentIdsOrdered[] = new String[documentIds.length];
    int i = 0;
    if (strTable.equals("C_INVOICE")) {
      printControllerData = PrintControllerData.selectInvoices(this, strIds.toString());
      for (PrintControllerData docID : printControllerData) {
        documentIdsOrdered[i++] = docID.getField("Id");
      }
    } else if (strTable.equals("C_ORDER")) {
      printControllerData = PrintControllerData.selectOrders(this, strIds.toString());
      for (PrintControllerData docID : printControllerData) {
        documentIdsOrdered[i++] = docID.getField("Id");
      }
    } else
      return documentIds;

    return documentIdsOrdered;
  }

  @Override
  public String getServletInfo() {
    return "Servlet that processes the print action";
  } // End of getServletInfo() method
}
