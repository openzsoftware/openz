package org.openz.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.servlet.ServletException;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.Sqlc;

public class CrudOperations {
  
   public static void UpdateCustomFields(String tabid,String IDKey,VariablesSecureApp vars,HttpSecureAppServlet servlet, Connection con) throws ServletException
   {
     String value="";
     String strTablename=CrudOperationsData.getTableFromTab(servlet, tabid);
     String strTableID=CrudOperationsData.getTableIDFromTab(servlet, tabid);
     String keyFieldname=CrudOperationsData.getIdColumnFromTable(servlet,  strTableID);
     CrudOperationsData[] data=CrudOperationsData.selectCustomColumns(servlet, tabid);
     if (data.length==0)
       return;
     String strSQL="UPDATE "+ strTablename + " SET ";
     for (int i=0;i<data.length;i++) {
       if (i>0)
         strSQL=strSQL + ",";
       strSQL=strSQL + data[i].pname + "=";
       if (data[i].ptype.equals("STRING")||data[i].ptype.equals("TIMESTAMP"))
         value="'" + vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(data[i].pname)).replaceAll("'", "'||chr(39)||'") + "'";
       if (data[i].ptype.equals("TIMESTAMP"))
         value="to_date(" + value + ",'" + vars.getSqlDateFormat() + "')";
       if (data[i].ptype.equals("NUMERIC"))
         value= vars.getNumericParameter("inp" + Sqlc.TransformaNombreColumna(data[i].pname));
       if (vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(data[i].pname)).isEmpty())
         value= "null";
       strSQL=strSQL + value;
     }
     strSQL=strSQL + " where " + keyFieldname + "='" + IDKey + "'";
     PreparedStatement st =null;
     try {
       st =  con.prepareStatement(strSQL);
       int updateCount = st.executeUpdate();
   } catch(SQLException e){
     throw new ServletException("@CODE=" + e.getSQLState() + "@" + e.getMessage());
   } catch(Exception ex){
     throw new ServletException("@CODE=@" + ex.getMessage());
   } finally {
     try {
         st.close();
       //.releaseTransactionalPreparedStatement(st);
     } catch(Exception ignore){
       ignore.printStackTrace();
     }
   }
   return;  
   }
   
   
   
}
