package org.openz.util;

import java.io.*;
import java.util.Date;

import org.openbravo.database.ConnectionProvider;
import org.openbravo.erpCommon.utility.Utility;

/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
public class FileUtils {
  public static void copyFile(String sourceDir,String destDir,String sourceFile, String destFile) throws Exception {
    
    final File toDir = new File(destDir);
    final File fromDir = new File(sourceDir);
    if (!toDir.exists())
      toDir.mkdirs();
    final File inputFile = new File(fromDir, sourceFile);
    final File outputFile = new File(toDir, destFile);
    FileInputStream in = new FileInputStream(inputFile);
    FileOutputStream out = new FileOutputStream(outputFile);
    byte[] buf = new byte[1024]; 
    int len; 
    while ((len = in.read(buf)) >= 0)  
      out.write(buf, 0, len); 
    in.close(); 
    out.flush();
    out.close(); 
  }
  
  public static String string2File(String destDir,String destFile, String content, Boolean overwrite) throws Exception {	    
	    final File toDir = new File(destDir);
	    if (!toDir.exists())
	      toDir.mkdirs();
	    File outputFile = new File(toDir, destFile);
	    // Avoid Dups in File Names
	    if ( outputFile.exists() && ! overwrite) {
	      final String dateOfPrint = Utility.formatDate(new Date(), "yyyy-MM-dd-HH:mm:ss"); 
	      outputFile = new File(destDir, dateOfPrint + "-" +destFile);
	    }   
	    PrintWriter out = new PrintWriter(outputFile);
	    out.print(content);
	    out.flush();
	    out.close(); 
	    return outputFile.getName();
  }
  
   public static String evalFile(String FileEnding){
	  String docTypeId="";
		  if (FileEnding.equals("ods"))
		  	docTypeId="06594D68EF324AAE8794E5E2BFF1AD3B";
		  if (FileEnding.equals("txt"))
			  	docTypeId="100D68EF324AAE8794E5E2BFF1AD3B";
		  if (FileEnding.equals("xls"))
			  	docTypeId="101";
		  if (FileEnding.equals("pdf"))
			  	docTypeId="103";
		  if (FileEnding.equals("doc"))
			  	docTypeId="104";
		  if (FileEnding.equals("pps"))
			  	docTypeId="105";
		  if (FileEnding.equals("zip"))
			  	docTypeId="107";
		  if (FileEnding.equals("jpg")||FileEnding.equals("peg"))
			  	docTypeId="108";
		  if (FileEnding.equals("gif"))
			  	docTypeId="109";
		  if (FileEnding.equals("odt"))
			  	docTypeId="5EDEA8C0B417462B9BC11283AE0BB3A5";
		  if (FileEnding.equals("tif"))
			  	docTypeId="800000";
		  if (FileEnding.equals("rtf"))
			  	docTypeId="800003";
		  if (FileEnding.equals("odp"))
			  	docTypeId="946957127C74449B8C62319189F9DED6";
		  if (FileEnding.equals("dwg"))
			  	docTypeId="9A4AF5CEEBB2425C8C2571F34AD1A6ED";
		  if (FileEnding.equals("png"))
			  	docTypeId="B97C7AA16C5443BCAC95A3FE9CEF3B76";
		  if (FileEnding.equals("sql"))
			  	docTypeId="DD72FCDFA3754A018F85B08113FB2899";
	  
	  return docTypeId;
  }
  
  public static String readFile(String filename) throws Exception{
    final File f = new File(filename);
    FileInputStream fstream = new FileInputStream(f);
    byte[] bytes = new byte[(int) f.length()];
    fstream.read(bytes);
    fstream.close();
    return new String(bytes);
  }
  
  public static String readFile(String filename, String path) throws Exception{
    final File dir = new File(path);
    final File f = new File(dir,filename);
    FileInputStream fstream = new FileInputStream(f);
    byte[] bytes = new byte[(int) f.length()];
    fstream.read(bytes);
    fstream.close();
    return new String(bytes);
  }
  
  public static void fileISO2UTF8(File file) throws Exception{
	  File tempfile=new File(file.getParent(), file.getName() + ".tmp");
     // file.renameTo(tempfile);
      InputStreamReader in = new InputStreamReader (new FileInputStream(file), "ISO-8859-15");
      BufferedReader inr = new BufferedReader(in);
      FileOutputStream fos = new FileOutputStream(tempfile);
      OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
      Writer out = new BufferedWriter(osw);
      String line;
      while ((line= inr.readLine())!=null) {
          out.write(line);
          out.write("\r\n");
      }
      out.close();
      in.close();
      file.delete();
      tempfile.renameTo(file);
}
  
  public static String attachFile(ConnectionProvider conn,String filename, String tableId, String recordID, String userId,String orgId, String text) throws Exception {
    return UtilsData.attachFile(conn, tableId, recordID, userId, filename, orgId, text);
  }
  
  public static String removeAttachedFile(ConnectionProvider conn,String filename, String tableId, String recordID) throws Exception {
    return UtilsData.remeveAttachFile(conn, tableId, recordID, filename);
  }
  
}
