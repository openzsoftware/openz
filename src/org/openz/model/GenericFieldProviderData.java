package org.openz.model;

import org.openbravo.data.FieldProvider;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Hashtable;
import java.util.Vector;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.openbravo.data.UtilSql;
import org.openbravo.database.ConnectionProvider;



public class GenericFieldProviderData  implements FieldProvider {
	static Logger log4j = Logger.getLogger(GenericFieldProviderData.class);
	public Hashtable <String,String> fieldvalues= new Hashtable <String,String> ();
	
	 public String getField(String fieldName) {
		   return fieldvalues.get(fieldName.toLowerCase());
		 }
	 public  static GenericFieldProviderData[] select(ConnectionProvider connectionProvider, String strSql)    throws ServletException {
		 ResultSet result;
		    Vector<java.lang.Object> vector = new Vector<java.lang.Object>(0);
		    
		    
		    PreparedStatement st = null;
		    try {
		  	    // Get the Whole Thing
			    st = connectionProvider.getPreparedStatement(strSql);
			    result = st.executeQuery();
			    ResultSetMetaData rsmd = result.getMetaData();
			    
			    while(result.next()) {	    	  
			    	GenericFieldProviderData locGenericFieldProviderData = new GenericFieldProviderData();
			    	for (int i=1;i<=rsmd.getColumnCount();i++) {
			    		locGenericFieldProviderData.fieldvalues.put(rsmd.getColumnName(i),UtilSql.getValue(result,rsmd.getColumnName(i)));
				    }
			    	vector.addElement(locGenericFieldProviderData);
			    }
		    
			    result.close();		  
		    } catch(SQLException e){
		      log4j.error("SQL error in query: " + strSql + "Exception:"+ e);
		      throw new ServletException("@CODE=" + e.getSQLState() + "@" + e.getMessage());
		    } catch(Exception ex){
		      log4j.error("Exception in query: " + strSql + "Exception:"+ ex);
		      throw new ServletException("@CODE=@" + ex.getMessage());
		    } finally {
		      try {
		        connectionProvider.releasePreparedStatement(st);
		      } catch(Exception ignore){}
		    }
		    GenericFieldProviderData objectGenericFieldProviderData[] = new GenericFieldProviderData[vector.size()];
		    vector.copyInto(objectGenericFieldProviderData);
		    return(objectGenericFieldProviderData);
		  }
	 
	 public  static String getSQL(ConnectionProvider connectionProvider, String strSql)    throws ServletException {
		 Statement stmt = null;
		 String retval=null;
		 try {
			 Connection dbcon = connectionProvider.getConnection();
	         stmt = dbcon.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
	            ResultSet.CONCUR_READ_ONLY);
	        ResultSet srs = stmt.executeQuery(strSql);
	        ResultSetMetaData rsmd = srs.getMetaData();
	        if (srs.first())
	          retval = srs.getString(rsmd.getColumnName(1));
	        dbcon.close();
		 } catch(SQLException e){
		      log4j.error("SQL error in query: " + strSql + "Exception:"+ e);
		      throw new ServletException("@CODE=" + e.getSQLState() + "@" + e.getMessage());
		    } catch(Exception ex){
		      log4j.error("Exception in query: " + strSql + "Exception:"+ ex);
		      throw new ServletException("@CODE=@" + ex.getMessage());
		    }
	        if (retval==null)
	          retval = "";
	        return retval;
		 
	 }	 
}
