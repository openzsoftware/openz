/*
 * ************************************************************************ The
 * contents of this file are subject to the Openbravo Public License Version 1.0
 * (the "License"), being the Mozilla Public License Version 1.1 with a
 * permitted attribution clause; you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 * http://www.openbravo.com/legal/license.html Software distributed under the
 * License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
 * either express or implied. See the License for the specific language
 * governing rights and limitations under the License. The Original Code is
 * Openbravo ERP. The Initial Developer of the Original Code is Openbravo SL All
 * portions are Copyright (C) 2001-2008 Openbravo SL All Rights Reserved.
 * Contributor(s): ______________________________________.
 * ***********************************************************************
 */
package org.openbravo.erpCommon.utility.poc;

import java.util.Properties;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;
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

import org.apache.log4j.Logger;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.utils.FormatUtilities;

public class EmailManager {
  private static Logger log4j = Logger.getLogger(EmailManager.class);
 
  private Boolean isSSL;
  /*
	 * 
	 */
  public Session newMailSession(ConnectionProvider connectionProvider, String clientId,
      String adOrgId) throws PocException, ServletException {
    PocConfigurationData configurations[];
    try {
      configurations = PocConfigurationData.getSmtpDetails(connectionProvider, clientId, adOrgId);
    } catch (ServletException exception) {
      throw new PocException(exception);
    }

    PocConfigurationData configuration = null;
    if (configurations.length > 0) {
      configuration = configurations[0];
      if (log4j.isDebugEnabled())
        log4j.debug("Crm configuration, smtp server: " + configuration.smtpserver);
      if (log4j.isDebugEnabled())
        log4j.debug("Crm configuration, smtp server auth: " + configuration.issmtpauthorization);
      if (log4j.isDebugEnabled())
        log4j.debug("Crm configuration, smtp server account: " + configuration.smtpserveraccount);
      if (log4j.isDebugEnabled())
        log4j.debug("Crm configuration, smtp server password: " + configuration.smtpserverpassword);
    } else {
      throw new ServletException("No Poc configuration found for this client.");
    }
    isSSL=false;
    Properties props = new Properties();
   // props.put("mail.debug", "true");
    props.put("mail.smtp.auth", (configuration.issmtpauthorization.equals("Y") ? "true" : "false"));
    //props.put("mail.smtp.mail.sender", "info@zimmermann-software.de");
    props.put("mail.host", configuration.smtpserver);
    if (configuration.smtpport!=null && ! configuration.smtpport.isEmpty())
      props.put("mail.smtp.port", configuration.smtpport);
    if (configuration.issmtpauthorization.equals("Y") && configuration.usetls.equals("Y") && configuration.usessl.equals("N")) {
      props.put("mail.smtp.starttls.enable", "true"); 
      props.put("mail.smtp.tls", "true");
      if (configuration.smtpport==null  || configuration.smtpport.isEmpty())
        props.put("mail.smtp.port", "587");
    }
    if (configuration.issmtpauthorization.equals("Y") && configuration.usessl.equals("Y")) {
      if (configuration.smtpport==null  || configuration.smtpport.isEmpty()) {
        props.put("mail.smtp.socketFactory.port", "465");
        props.put("mail.smtp.port", "465");
      } else 
        props.put("mail.smtp.socketFactory.port",  configuration.smtpport);
      props.put("mail.smtp.socketFactory.class","javax.net.ssl.SSLSocketFactory"); 
      props.put("mail.smtps.auth", "true"); 
      props.put("mail.smtp.ssl.checkserveridentity", "true");
      props.put("mail.transport.protocol", "smtps");
      props.put("mail.smtps.starttls.enable", "true");
      props.put("mail.smtp.ssl.enable", "true");
      isSSL=true;
    } else
      props.put("mail.transport.protocol", "smtp");
    

    ClientAuthenticator authenticator = null;
    if (configuration.smtpserveraccount != null) {
      authenticator = new ClientAuthenticator(configuration.smtpserveraccount,
          configuration.smtpserverpassword);
    }
//    if (configuration.smtpserveraccount != null) {
//      authenticator = new ClientAuthenticator(configuration.smtpserveraccount, FormatUtilities
//          .encryptDecrypt(configuration.smtpserverpassword, false));
//    }

    return Session.getInstance(props, authenticator);
  }

  /*
	 * 
	 */
  public void sendSimpleEmail(Session session, String from, String to, String bcc, String subject,
      String body, String attachmentFileLocations) throws PocException {
    try {
      Message message = new MimeMessage(session);
      message.setFrom(new InternetAddress(from));

      message.setRecipients(Message.RecipientType.TO, getAddressesFrom(to.split(",")));

      if (bcc != null && ! bcc.isEmpty())
        message.setRecipients(Message.RecipientType.BCC, getAddressesFrom(bcc.split(",")));

      message.setSubject(subject);

      // Content consists of 2 parts, the message body and the attachment
      // We therefore use a multipart message
      Multipart multipart = new MimeMultipart();

      // Create the message part
      MimeBodyPart messageBodyPart = new MimeBodyPart();
      messageBodyPart.setContent(body, "text/html; charset=utf-8");
      multipart.addBodyPart(messageBodyPart);

      // Create the attachment parts
      if (attachmentFileLocations != null && !attachmentFileLocations.isEmpty()) {
        String attachments[] = attachmentFileLocations.split(",");

        for (String attachment : attachments) {
          messageBodyPart = new MimeBodyPart();
          DataSource source = new FileDataSource(attachment);
          messageBodyPart.setDataHandler(new DataHandler(source));
          messageBodyPart.setFileName(attachment.substring(attachment.lastIndexOf("/") + 1));
          multipart.addBodyPart(messageBodyPart);
        }
      }

      message.setContent(multipart);
      // Send the email
      Transport.send(message);
      
    } catch (AddressException exception) {
      throw new PocException(exception);
    } catch (MessagingException exception) {
      throw new PocException(exception);
    }
  }

  private InternetAddress[] getAddressesFrom(String[] textualAddresses) {
    InternetAddress internetAddresses[] = new InternetAddress[textualAddresses.length];
    for (int index = 0; index < textualAddresses.length; index++) {
      try {
        internetAddresses[index] = new InternetAddress(textualAddresses[index]);
      } catch (AddressException e) {
        if (log4j.isDebugEnabled())
          log4j.debug("Could not create a valid email for: " + textualAddresses[index]
              + ". Address ignored");
      }
    }
    return internetAddresses;
  }

}
