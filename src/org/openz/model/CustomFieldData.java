package org.openz.model;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.Vector;

import javax.servlet.ServletException;

import org.openbravo.data.FieldProvider;
import org.openbravo.data.UtilSql;
import org.openbravo.database.ConnectionProvider;

public class CustomFieldData implements FieldProvider {
      
  private Vector <String> fields= new Vector<String>();
  private Vector <String> types= new Vector<String>();
  private Vector <String> names= new Vector<String>();
      
    public String getField(String fieldName) {
      int counter=0;
      for (int i=0;i<names.size();i++) {
        if (names.elementAt(i).equals(fieldName))
        	return fields.elementAt(i);
      }
      return null;
    }
     
   

      public  CustomFieldData select(ConnectionProvider connectionProvider, String referenceid, String tabId, String keycolumnname)    throws ServletException {
        String strTablename=CrudOperationsData.getTableFromTab(connectionProvider, tabId);
        String customcount=CrudOperationsData.getCustomColumnCount(connectionProvider, tabId);
        if (Integer.parseInt(customcount)==0)
          return null;
        CrudOperationsData[] data=CrudOperationsData.selectCustomColumns(connectionProvider, tabId);
        if (data.length==0)
          return null;
        String strSql = " select ";
        for (int i=0; i< data.length;i++) {
          types.add(data[i].ptype);
          if (!strSql.equals(" select "))
            strSql = strSql + ",";
          strSql = strSql + data[i].pname;
          names.add(data[i].pname);
        }
        
        strSql = strSql +  " from " + strTablename + " where " + keycolumnname + "='" + referenceid + "'";
        ResultSet result;
        CustomFieldData objectCustomFieldData = new CustomFieldData();
        
        PreparedStatement st = null;
       
        
        try {
        st = connectionProvider.getPreparedStatement(strSql);
          
          result = st.executeQuery();
        
          
          while(result.next()) {
            for (int i=0; i< Integer.parseInt(customcount);i++) {
              if (types.get(i).equals("TIMESTAMP"))
                fields.add(UtilSql.getDateValue(result, names.get(i), "dd-MM-yyyy"));
              else
                fields.add(UtilSql.getValue(result, names.get(i)));
            }  
          }
          result.close();
        } catch(SQLException e){
          
          throw new ServletException("@CODE=" + e.getSQLState() + "@" + e.getMessage());
        } catch(Exception ex){
          
          throw new ServletException("@CODE=@" + ex.getMessage());
        } finally {
          try {
            connectionProvider.releasePreparedStatement(st);
          } catch(Exception ignore){
            ignore.printStackTrace();
          }
        }
        
        return(objectCustomFieldData);
      }

}
