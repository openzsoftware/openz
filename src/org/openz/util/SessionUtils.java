package org.openz.util;
import org.openbravo.data.Sqlc;

import javax.servlet.http.HttpServletRequest;

import org.openbravo.base.secureApp.VariablesSecureApp;
public class SessionUtils {
  public static void setLocalSessionVariable(String servlet,VariablesSecureApp vars, String ADName) {
    vars.setSessionValue(servlet + "|" + ADName, vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(ADName)));
  }
  public static String readInputAndSetLocalSessionVariable(String servlet,VariablesSecureApp vars, String ADName) {
    vars.setSessionValue(servlet + "|" + ADName, vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(ADName)));
    return vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(ADName));
  }
  public static String readInput(VariablesSecureApp vars, String ADName) {
    return vars.getStringParameter("inp" + Sqlc.TransformaNombreColumna(ADName));
  }
  public static void setLocalSessionVariable(String servlet,VariablesSecureApp vars, String ADName, String Value) {
    vars.setSessionValue(servlet + "|" +  ADName, Value);
  }
  
  public static String getLocalSessionVariable(String servlet,VariablesSecureApp vars, String ADName) {
    return vars.getSessionValue(servlet + "|" + ADName);
  }
  
  public static void deleteLocalSessionVariable(String servlet,VariablesSecureApp vars, String ADName) {
    vars.removeSessionValue(servlet + "|" + ADName);
  }
  public static Boolean isMobileClient(HttpServletRequest request) {
    String  browserDetails  =   request.getHeader("User-Agent");
    String  userAgent       =   browserDetails;
    String  user            =   userAgent.toLowerCase();

    String os = "";
    String browser = "";

    //=================OS=======================
     if (userAgent.toLowerCase().indexOf("windows") >= 0 )
     {
         os = "Windows";
     } else if(userAgent.toLowerCase().indexOf("mac") >= 0)
     {
         os = "Mac";
     } else if(userAgent.toLowerCase().indexOf("x11") >= 0)
     {
         os = "Unix";
     } else if(userAgent.toLowerCase().indexOf("android") >= 0)
     {
         os = "Android";
     } else if(userAgent.toLowerCase().indexOf("iphone") >= 0)
     {
         os = "IPhone";
     }else{
         os = "UnKnown, More-Info: "+userAgent;
     }
     //===============Browser===========================
    if (user.contains("msie"))
    {
        String substring=userAgent.substring(userAgent.indexOf("MSIE")).split(";")[0];
        browser=substring.split(" ")[0].replace("MSIE", "IE")+"-"+substring.split(" ")[1];
    } else if (user.contains("safari") && user.contains("version"))
    {
        browser=(userAgent.substring(userAgent.indexOf("Safari")).split(" ")[0]).split("/")[0]+"-"+(userAgent.substring(userAgent.indexOf("Version")).split(" ")[0]).split("/")[1];
    } else if ( user.contains("opr") || user.contains("opera"))
    {
        if(user.contains("opera"))
            browser=(userAgent.substring(userAgent.indexOf("Opera")).split(" ")[0]).split("/")[0]+"-"+(userAgent.substring(userAgent.indexOf("Version")).split(" ")[0]).split("/")[1];
        else if(user.contains("opr"))
            browser=((userAgent.substring(userAgent.indexOf("OPR")).split(" ")[0]).replace("/", "-")).replace("OPR", "Opera");
    } else if (user.contains("chrome"))
    {
        browser=(userAgent.substring(userAgent.indexOf("Chrome")).split(" ")[0]).replace("/", "-");
    } else if ((user.indexOf("mozilla/7.0") > -1) || (user.indexOf("netscape6") != -1)  || (user.indexOf("mozilla/4.7") != -1) || (user.indexOf("mozilla/4.78") != -1) || (user.indexOf("mozilla/4.08") != -1) || (user.indexOf("mozilla/3") != -1) )
    {
        //browser=(userAgent.substring(userAgent.indexOf("MSIE")).split(" ")[0]).replace("/", "-");
        browser = "Netscape-?";

    } else if (user.contains("firefox"))
    {
        browser=(userAgent.substring(userAgent.indexOf("Firefox")).split(" ")[0]).replace("/", "-");
    } else if(user.contains("rv"))
    {
        browser="IE";
    } else
    {
        browser = "UnKnown, More-Info: "+userAgent;
    }
    if (os.equals("IPhone")||os.equals("Android"))
      return true;
    else
      return false;
  }
}
