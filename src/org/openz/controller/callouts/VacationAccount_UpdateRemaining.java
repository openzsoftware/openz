package org.openz.controller.callouts;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

import com.sun.jna.platform.win32.Winioctl.STORAGE_DEVICE_NUMBER;


public class VacationAccount_UpdateRemaining extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;
  private static final String inp_bpartner = "inpcBpartnerId";
  private static final String inp_month = "inpwmonth";
  private static final String inp_year = "inpwyear";
  private static final String inp_lastfieldchanged = "inpLastFieldChanged";
  private static final String inp_remaining = "inpremaining";
  private static final String query_getHolidayEntitlement = "SELECT zssi_getHolidayEntitlement(?, ?, ?)";

  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
    VariablesSecureApp vars = new VariablesSecureApp(request);
    if (vars.commandIn("DEFAULT")) {
      
      // New Callout Structure
      CalloutStructure callout = new CalloutStructure(this, this.getClass().getSimpleName() );
      
      try {
    	  
    	updateRemainingField(vars, callout);
        
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println(callout.returnCalloutAppFrame());
        out.close();
      } catch (Exception ex) {
        pageErrorCallOut(response);
      }
    } else
      pageError(response);
  }
  
  public void updateRemainingField(VariablesSecureApp vars, CalloutStructure callout) throws Exception {
	  
	  	String strLastChangedField = vars.getStringParameter(inp_lastfieldchanged);
    	if (strLastChangedField.equals(inp_month) || strLastChangedField.equals(inp_year)) {
    		  
    		  String strCalculatedRemaining = Double.toString(getCalculatedRemaining(vars));
    		  callout.appendNumeric(inp_remaining, strCalculatedRemaining);
    	}
  }
  
  public double getCalculatedRemaining(VariablesSecureApp vars)throws Exception {
	  

	  PreparedStatement preparedStatement = this.getPreparedStatement(query_getHolidayEntitlement);
	  setPreparedStatementParameters(vars, preparedStatement);

	  ResultSet resultSet = preparedStatement.executeQuery(); 

	  resultSet.next();
	  return resultSet.getDouble(1);
  }
  
  public void setPreparedStatementParameters(VariablesSecureApp vars, PreparedStatement preparedStatement) throws SQLException, ServletException {

	  String strBpartner = vars.getStringParameter(inp_bpartner);
	  String strWMonth = vars.getStringParameter(inp_month);
	  String strWYear = vars.getStringParameter(inp_year);

	  preparedStatement.setString(1, strBpartner);
	  preparedStatement.setString(2, strWMonth); 
	  preparedStatement.setString(3, strWYear);
  }
}
