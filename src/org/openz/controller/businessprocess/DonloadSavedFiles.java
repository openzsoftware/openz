package org.openz.controller.businessprocess;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.FileUtils;
import org.apache.log4j.Logger;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.zsoft.datev.DatevExportService;
import org.openz.util.UtilsData;

public class DonloadSavedFiles {
  private static final Logger log = Logger.getLogger(DatevExportService.class);

  public void execute(ProcessBundle bundle, HttpSecureAppServlet servlet,HttpServletResponse response) throws Exception {

    log.debug("Starting DatevExportService.\n");
 
    String file= processRequest(bundle);

    servlet.printPagePopUpDownloadFile(response.getOutputStream(), file, "/tmp");
    final OBError msg = new OBError();
    msg.setType("Success");
    msg.setMessage("Download-Service Successful execution.");
    msg.setTitle("Done");
    bundle.setResult(msg);
  }

private String processRequest(ProcessBundle bundle) throws Exception {
 
    final String yearID = (String) bundle.getParams().get("cYearId");
    
    String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
    String lang=bundle.getContext().getLanguage();
    
   
    // Get SQL Prepared..
    ConnectionProvider connp = bundle.getConnection();
    FileInputStream from = null; // Stream to read from source
    FileOutputStream to = null; // Stream to write to destination
    String year=BprocessCommonData.getYear(connp, yearID);
    String filename="OpenzFiles-"+year+".zip";
    FileUtils.deleteDirectory(new File(fileDir + "/tmp/"));
    File fi = new File(fileDir + "/tmp/content/");
    fi.mkdirs();
    FileOutputStream f = new FileOutputStream(fileDir + "/tmp/" + filename);
    ZipOutputStream zip = new ZipOutputStream(new BufferedOutputStream(f));
    BprocessCommonData[] data = BprocessCommonData.selectFiles(connp, year);
    File fo;
    for (int i=0;i<data.length;i++) {
      fi = new File(fileDir + "/tmp/content/" + BprocessCommonData.getTableName(connp, bundle.getContext().getLanguage(), data[i].adTableId)+ "/");
      if (! fi.exists())
        fi.mkdirs();
      fi = new File(fileDir + "/tmp/content/" + BprocessCommonData.getTableName(connp, bundle.getContext().getLanguage(), data[i].adTableId) + "/" + BprocessCommonData.getIdentifierfromTabIdr(connp, data[i].adTableId, data[i].adRecordId,lang).replace("/", "-") + "-" + data[i].name );
      if (fi.exists())
        fi = new File(fileDir + "/tmp/content/" + BprocessCommonData.getTableName(connp, bundle.getContext().getLanguage(), data[i].adTableId) + "/" + BprocessCommonData.getIdentifierfromTabIdr(connp, data[i].adTableId, data[i].adRecordId,lang).replace("/", "-") + "-" + UtilsData.getUUID(connp) + "_" + data[i].name );
      fo= new File (fileDir + "/" + data[i].adTableId + "-" + data[i].adRecordId + "/" + data[i].name);
      if (fo.exists()) {
        from= new FileInputStream(fo);
        to=new FileOutputStream(fi);
        byte[] buffer = new byte[4096];
        int bytes_read;
        while ((bytes_read = from.read(buffer)) != -1)
          // Read until EOF
          to.write(buffer, 0, bytes_read); // write
        from.close();
        to.close();
      }
      
    }
    data = BprocessCommonData.selectFilesDeleted(connp, year);
    for (int i=0;i<data.length;i++) {
      fi = new File(fileDir + "/tmp/content/" + BprocessCommonData.getTableName(connp, bundle.getContext().getLanguage(), data[i].adTableId)+ "/deleted/");
      if (! fi.exists())
        fi.mkdirs();
      fi = new File(fileDir + "/tmp/content/" + BprocessCommonData.getTableName(connp, bundle.getContext().getLanguage(), data[i].adTableId) + "/deleted/" + BprocessCommonData.getIdentifierfromTabIdr(connp, data[i].adTableId, data[i].adRecordId,lang) + "-" + data[i].name );
      if (fi.exists())
        fi = new File(fileDir + "/tmp/content/" + BprocessCommonData.getTableName(connp, bundle.getContext().getLanguage(), data[i].adTableId) + "/deleted/" + BprocessCommonData.getIdentifierfromTabIdr(connp, data[i].adTableId, data[i].adRecordId,lang) + "-" + UtilsData.getUUID(connp) + "_" + data[i].name );
      fo= new File (fileDir + "/" + data[i].adTableId + "-" + data[i].adRecordId + "/" + data[i].name);
      if (fo.exists()) {
        from= new FileInputStream(fo);
        to=new FileOutputStream(fi);
        byte[] buffer = new byte[1024];
        int bytes_read;
        while ((bytes_read = from.read(buffer)) != -1)
          // Read until EOF
          to.write(buffer, 0, bytes_read); // write
        from.close();
        to.close();
      }
    }
    fi = new File(fileDir + "/tmp/content/");
    addDirToArchive(zip,fi);
    zip.close();
    FileUtils.deleteDirectory(new File(fileDir + "/tmp/content/"));
    log.debug("Creation of File Successfully finished\n");
    return filename;
    
 
}
private static void addDirToArchive(ZipOutputStream zos, File srcFile) throws Exception  {

final  File[] files = srcFile.listFiles();

 // System.out.println("Adding directory: " + srcFile.getName());

  for (int i = 0; i < files.length; i++) {
          
          // if the file is directory, use recursion
          if (files[i].isDirectory()) {
                  addDirToArchive(zos, files[i]);
                  continue;
          }

          try {
                  
                 // System.out.println("tAdding file: " + files[i].getName());

                  // create byte buffer
                  byte[] buffer = new byte[1024];

                  FileInputStream fis = new FileInputStream(files[i]);
                  String tt = files[i].getPath();
                  zos.putNextEntry(new ZipEntry(tt));
                  
                  int length;

                  while ((length = fis.read(buffer)) > 0) {
                          zos.write(buffer, 0, length);
                  }

                  zos.closeEntry();

                  // close the InputStream
                  fis.close();

          } catch (Exception ioe) {
                  throw new Exception ("PackingZIPException :" + ioe);
          }
          
  }

}
}
