/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.openbravo.zsoft.service;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import org.openbravo.database.ConnectionProvider;
import javax.servlet.ServletException;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;

public class Util {

   public String getText(String message,String language,ConnectionProvider connp) throws ServletException {
     String retval="";
     try {
       Connection conn = connp.getConnection();
       String sql = "select  zssi_getText('" + message + "','" + language +"') as text from dual";   
       Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
         ResultSet.CONCUR_READ_ONLY);
     ResultSet res = stmt.executeQuery(sql);
     if (res.first())
       retval = res.getString("text");
     conn.close();
   } catch (Exception e) {
     // catch any possible exception and throw it as Servlet Ex
     throw new ServletException(e.getMessage(), e);
   }
     return retval;
   }
   
   public static String padRight(String s, int n) {
     return String.format("%1$-" + n + "s", s);
   }

   public static String padLeft(String s, int n) {
     return String.format("%1$#" + n + "s", s);
   }
   
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
}
