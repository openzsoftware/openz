package org.openbravo.erpCommon.utility.reporting.printing;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
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
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.data.FieldProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.erpCommon.utility.poc.EmailManager;
import org.openbravo.erpCommon.utility.poc.PocException;
import org.openbravo.erpCommon.utility.reporting.DocumentType;
import org.openbravo.erpCommon.utility.reporting.EmailDefinitionData;
import org.openbravo.erpCommon.utility.reporting.Report;
import org.openbravo.erpCommon.utility.reporting.ReportManager;
import org.openbravo.erpCommon.utility.reporting.Report.OutputTypeEnum;

public class OutPutMgmtPrintController {
	
	
	public void process(VariablesSecureApp vars,ConnectionProvider connection,
		      DocumentType documentType, String sessionValuePrefix, String strDocumentId,String basepath,String isByEMail,String cDoctypeId,String adOrgId)
		      throws Exception {
		String lang= vars.getLanguage();
		String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
		OutputTypeEnum outType;
		final ReportManager reportManager = new ReportManager(connection, fileDir,
		        "../web", "src-loc","design", basepath, false,lang,lang,documentType);
		if (isByEMail.equals("Y"))
			outType=OutputTypeEnum.EMAIL;
		else
			outType=OutputTypeEnum.ARCHIVE;
		final Report report;
		String template=PrintControllerData.GetDefaultDoctypeTempate(connection, cDoctypeId, adOrgId);
		report = new Report(connection, documentType, strDocumentId, lang, template,
		          false, outType);
		reportManager.setTargetDirectory(report);
		final String tableId = ToolsData.getTableId(connection, report.getDocumentType().getTableName());
		reportManager.createAttachmentForReport(connection, report, tableId, vars);
		if (isByEMail.equals("Y")) {
			
		}
		
		
	}
	
	void sendDocumentEmail(Report report, VariablesSecureApp vars, ConnectionProvider connection,
		      PocData documentData, String senderAddess,String template, String lang,String fileDir )
		      throws Exception {
		    final String documentId = report.getDocumentId();
		    final String attachmentFileLocation = report.getTargetLocation();

		    final String ourReference = report.getOurReference();
		    final String cusReference = report.getCusReference();
		    
		    // Also send it to the current user
		   
		    final String userName = documentData.salesrepName;
		    final String userEmail = documentData.salesrepEmail;
		    
		    final String contactName = documentData.contactName;
		    String contactEmail = null;
		    String contactCCEmail = null;
		    final String salesrepName = documentData.salesrepName;
		    String salesrepEmail = null;

		    
		    
		      contactEmail =documentData.contactEmail;
		      contactCCEmail = documentData.contactCcemail;

		      if (EmailDefinitionData.getCentalSenderEmail(connection).isEmpty())
		        salesrepEmail = documentData.salesrepEmail;
		      else
		        salesrepEmail = EmailDefinitionData.getCentalSenderEmail(connection);
		    EmailOptionsData[] eod=EmailOptionsData.selectByTemplate(connection, lang, template);
		    String emailSubject = eod[0].subject;
		    String emailBody = eod[0].emailbody;


		    if ((salesrepEmail == null || salesrepEmail.length() == 0)) {
		      throw new MessagingException(Utility.messageBD(connection, "NoSalesRepEmail", vars.getLanguage()));
		    }

		    if ((contactEmail == null || contactEmail.length() == 0)) {
		      throw new MessagingException(Utility.messageBD(connection, "NoCustomerEmail", vars.getLanguage()));
		    }

		    // Replace special tags

		    emailSubject = emailSubject.replaceAll("@cus_ref@", cusReference);
		    emailSubject = emailSubject.replaceAll("@our_ref@", ourReference);
		    emailSubject = emailSubject.replaceAll("@cus_nam@", contactName);
		    emailSubject = emailSubject.replaceAll("@sal_nam@", salesrepName);

		    emailBody = emailBody.replaceAll("@cus_ref@", cusReference);
		    emailBody = emailBody.replaceAll("@our_ref@", ourReference);
		    emailBody = emailBody.replaceAll("@cus_nam@", contactName);
		    emailBody = emailBody.replaceAll("@sal_nam@", salesrepName);

		      EmailManager mailman = new EmailManager(); 
		      final Session session = mailman.newMailSession(connection, vars.getClient(), report.getOrgId());

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

		      // Create the attachment part
		      messageBodyPart = new MimeBodyPart();
		      final DataSource source = new FileDataSource(attachmentFileLocation);
		      messageBodyPart.setDataHandler(new DataHandler(source));
		      messageBodyPart.setFileName(attachmentFileLocation.substring(attachmentFileLocation
		          .lastIndexOf("/") + 1));
		      multipart.addBodyPart(messageBodyPart);
		      //
		      // Add eventually Attachments of the EMail Template
		      
		      eod=EmailOptionsData.selectAttachmentsByTemplate(connection, template,lang);
		      for (int i=0; i< eod.length; i++) {
		    	  final File file = new File(fileDir + "/" +  eod[i].attachments);
		    	  messageBodyPart = new MimeBodyPart();
		          messageBodyPart.attachFile(file);
		          multipart.addBodyPart(messageBodyPart);
		      }

		      message.setContent(multipart);

		      // Send the email
		      Transport.send(message);
		    
		  }
}
