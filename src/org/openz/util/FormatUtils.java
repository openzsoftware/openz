package org.openz.util;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.math.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.*;

import org.openbravo.base.secureApp.VariablesSecureApp;
public class FormatUtils {
  // Format : qtyEdition, integerEdition, priceEdition, euroEdition
  public static String formatNumber(String fieldValue,VariablesSecureApp vars,String formatstr){
    
    String format=vars.getSessionValue("#FORMATOUTPUT|" + formatstr.toUpperCase());
    String group=vars.getSessionValue("#GROUPSEPARATOR|"+ formatstr.toUpperCase());
    String decimal= vars.getSessionValue("#DECIMALSEPARATOR|"+ formatstr.toUpperCase());
    DecimalFormat numberFormatDecimal = null;
    if (format != null && !format.equals("") && decimal != null && !decimal.equals("")
        && group != null && !group.equals("")) {
      DecimalFormatSymbols dfs = new DecimalFormatSymbols();
      dfs.setDecimalSeparator(decimal.charAt(0));
      dfs.setGroupingSeparator(group.charAt(0));
      numberFormatDecimal = new DecimalFormat(format, dfs);
    }
    if (fieldValue == null || fieldValue.equals(""))
      return ""; // if the string is empty then Double.parseDouble cannot
    //DH. Buscador saves numeric Values wrong in Session. Numeric with comma is not a numeric.
      if (fieldValue.contains(",")) {
        fieldValue=fieldValue.replace(".", "");
        fieldValue=fieldValue.replace(",", ".");        
      }
      return numberFormatDecimal.format(new BigDecimal(fieldValue));
  }
  
  // Translates ID-Field Values e.g c_bpartner_id > cBpartnerId
  // For OLD-Style Response-field Access in Servlets
  public static String field2form(String fieldValue){
      final int numChars = fieldValue.length();
      final StringBuilder result = new StringBuilder(numChars);
      boolean underscore = false;
      for (int i = 0; i < numChars; i++) {
        final char curr = fieldValue.charAt(i);
        if (i == 0) {
            result.append(Character.toLowerCase(curr));
        } else {
          if (curr == '_')
            underscore = true;
          else {
            if (underscore) {
              result.append(Character.toUpperCase(curr));
              underscore = false;
            } else {
                result.append(Character.toLowerCase(curr));
            }
          }
        }
      }
      return result.toString();
  }
  public static String vector2sqlForm(Vector<String> fieldValue){
    String retval="(";
    for (int i = 0; i < fieldValue.size(); i++){
      if (i>0)
        retval=retval+",";
      retval=retval+"'" + fieldValue.elementAt(i) + "'"; 
    }
    if (fieldValue.size()==0)
      retval=retval+"''";
    return retval+")";
  }
  public static String date2sqltimestamp(Date date,VariablesSecureApp vars) {
    final String dateTimeFormat = vars.getJavaDataTimeFormat();
    return date == null ? null : new SimpleDateFormat(dateTimeFormat).format(date);
  }
  
  public static int ordinalIndexOf(String str, String c, int n) {
    int pos = str.indexOf(c, 0);
    while (n-- > 0 && pos != -1)
        pos = str.indexOf(c, pos+1);
    return pos;
}
  public static DecimalFormat getNumberFormat(VariablesSecureApp vars) {
    final DecimalFormatSymbols dfs = new DecimalFormatSymbols();
    dfs.setDecimalSeparator(vars.getSessionValue("#AD_ReportDecimalSeparator").charAt(0));
    dfs.setGroupingSeparator(vars.getSessionValue("#AD_ReportGroupingSeparator").charAt(0));
    final DecimalFormat numberFormat = new DecimalFormat(vars.getSessionValue("#AD_ReportNumberFormat"), dfs);
   return numberFormat;
  }
  
  public static Boolean isNix(String s) {
	  if (s==null)
		  return true;
	  if (s.isEmpty())
		  return true;
	  else
		  return false;	  
  }	    
  
}
