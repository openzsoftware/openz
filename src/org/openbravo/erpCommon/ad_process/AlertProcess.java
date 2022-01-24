package org.openbravo.erpCommon.ad_process;


import javax.mail.Session;


import org.openbravo.database.ConnectionProvider;

import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.erpCommon.utility.poc.EmailManager;
import org.openbravo.scheduling.Process;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessLogger;
import org.openbravo.utils.Replace;
import org.openz.util.UtilsData;
import org.quartz.JobExecutionException;

public class AlertProcess implements Process {

  private static int counter = 0;

  private ConnectionProvider connection;
  private ProcessLogger logger;

  public void execute(ProcessBundle bundle) throws Exception {

    logger = bundle.getLogger();
    connection = bundle.getConnection();

    logger.log("Starting Alert Backgrouond Process. Loop " + counter + "\n");

    try {
      AlertProcessData[] alertRule = AlertProcessData.selectSQL(connection);
      if (alertRule != null && alertRule.length != 0) {

        for (int i = 0; i < alertRule.length; i++) {
          processAlert(alertRule[i]);
        }
      }
    } catch (Exception e) {
      throw new JobExecutionException(e.getMessage(), e);
    }
  }

  /**
   * @param alertRule
   * @param connection
   * @throws Exception
   */
  private void processAlert(AlertProcessData alertRule)
      throws Exception {
    logger.log("Processing rule " + alertRule.name + "\n");

    AlertProcessData[] alert = null;

    if (!alertRule.sql.equals("")) {
      try {
    	  AlertProcessData.DeleteWhenNotFixed(connection, alertRule.adAlertruleId);
          alert = AlertProcessData.selectAlert(connection, alertRule.sql);
        
      } catch (Exception ex) {
        logger.log("Error processing: " + ex.getMessage() + "\n");
        return;
      }
    }
    // Insert
    if (alert != null && alert.length != 0) {
      int insertions = 0;
      StringBuilder msg = new StringBuilder();

      for (int i = 0; i < alert.length; i++) {
        if (AlertProcessData.existsReference(connection, alertRule.adAlertruleId,
            alert[i].referencekeyId).equals("0")) {

          String adAlertId = SequenceIdData.getUUID();

          logger.log("Inserting alert " + adAlertId + " org:" + alert[i].adOrgId + " client:"
              + alert[i].adClientId + " reference key: " + alert[i].referencekeyId + " created"
              + alert[i].created + "\n");
          AlertProcessData.InsertAlert(connection, adAlertId, alert[i].adClientId,
              alert[i].adOrgId, alert[i].created, alert[i].createdby, alertRule.adAlertruleId,
              alert[i].recordId, alert[i].referencekeyId, alert[i].description, alert[i].adUserId,
              alert[i].adRoleId);

          msg.append("\n\nAlert: " + alert[i].description + "\nRecord: " + alert[i].recordId);
          // Send mail
         
          AlertProcessData[] mail = AlertProcessData.prepareMails(connection, alertRule.adAlertruleId,adAlertId,alert[i].adUserId);
          if (mail != null) {  
            if (mail.length>0) {
              
              String bcc="";
              if (UtilsData.getOrgConfigOption(connection, "addbccemail2alerts", alert[i].adOrgId).equals("Y"))
                bcc=AlertProcessData.getBccAddress(connection, "C726FEC915A54A0995C568555DA5BB3C", alert[i].adOrgId);
             EmailManager mailman = new EmailManager();
             final Session session = mailman.newMailSession(connection, "C726FEC915A54A0995C568555DA5BB3C", alert[i].adOrgId);
             for (int j = 0; j < mail.length; j++) {
               
                
                StringBuilder msge = new StringBuilder();  
                msge.append(mail[j].description);
                String head = Utility.messageBD(connection, "AlertMailHead", mail[j].adLanguage);
                String foot = "\n" + Utility.messageBD(connection, "AlertMailFoot", mail[j].adLanguage);
                String mailmsg=msge.toString() + foot;
                mailmsg =Replace.replace(mailmsg, "ü", "ue");
                mailmsg =Replace.replace(mailmsg, "ö", "oe");
                mailmsg =Replace.replace(mailmsg, "ä", "ae");
                mailmsg =Replace.replace(mailmsg, "ß", "ss");
                mailmsg =Replace.replace(mailmsg, "Ü", "Ue");
                mailmsg =Replace.replace(mailmsg, "Ä", "Ae");
                mailmsg =Replace.replace(mailmsg, "Ö", "Oe");
                
                try {
                  // Send the mail, last param could be Attchment :-)
                  mailman.sendSimpleEmail(session, mail[j].mailfrom,mail[j].mailto, bcc, alertRule.name, mailmsg,null);
                  logger.log("Mail sent ok.");
                }
                catch (Exception e) {
                  logger.log("Error sending mail.");
                  logger.log(e.getMessage());
                }                 
             }
            }
          }
        }
      }
     
    }

    // Update
    if (!alertRule.sql.equals("")) {
      try {
        // Set isactive='N' when rule doesn't fit anymore and deactvatewhennotapplied='Y' an alertrule
        Integer count = AlertProcessData.updateAlert(connection, alertRule.adAlertruleId,
            alertRule.sql);
        logger.log("updated alerts: " + count + "\n");

      } catch (Exception ex) {
        logger.log("Error updating: " + ex.toString() + "\n");
      }
    }
  }

}