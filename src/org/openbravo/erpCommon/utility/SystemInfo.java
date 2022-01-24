/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html 
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License. 
 * The Original Code is Openbravo ERP. 
 * The Initial Developer of the Original Code is Openbravo SL 
 * All portions are Copyright (C) 2008-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */

package org.openbravo.erpCommon.utility;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.ServletException;

import org.openbravo.database.ConnectionProvider;

public class SystemInfo {

  private static Map<Item, String> systemInfo;

  static {
    systemInfo = new HashMap<Item, String>();
  }

  public static void load(ConnectionProvider conn) throws ServletException {
    for (Item i : Item.values()) {
      load(i, conn);
    }
  }

  private static void load(Item i, ConnectionProvider conn) throws ServletException {
    switch (i) {
    case SYSTEM_IDENTIFIER:
      systemInfo.put(i, getSystemIdentifier(conn));
      break;
    case DATABASE:
      systemInfo.put(i, conn.getRDBMS());
      break;
    case DATABASE_VERSION:
      systemInfo.put(i, getDatabaseVersion(conn));
      break;
    case WEBSERVER:
      systemInfo.put(i, getWebserver(conn)[0]);
      break;
    case WEBSERVER_VERSION:
      systemInfo.put(i, getWebserver(conn)[1]);
      break;
    case SERVLET_CONTAINER:
      systemInfo.put(i, SystemInfoData.selectServletContainer(conn));
      break;
    case SERVLET_CONTAINER_VERSION:
      systemInfo.put(i, SystemInfoData.selectServletContainerVersion(conn));
      break;
    case ANT_VERSION:
      systemInfo.put(i, getVersion(SystemInfoData.selectAntVersion(conn)));
      break;
    case OB_VERSION:
      systemInfo.put(i, SystemInfoData.selectObVersion(conn));
      break;
    case OB_INSTALL_MODE:
      systemInfo.put(i, SystemInfoData.selectObInstallMode(conn));
      break;
    case CODE_REVISION:
      systemInfo.put(i, SystemInfoData.selectCodeRevision(conn));
      break;
    case NUM_REGISTERED_USERS:
      systemInfo.put(i, SystemInfoData.selectNumRegisteredUsers(conn));
      break;
    case ISHEARTBEATACTIVE:
      systemInfo.put(i, SystemInfoData.selectIsheartbeatactive(conn));
      break;
    case ISPROXYREQUIRED:
      systemInfo.put(i, SystemInfoData.selectIsproxyrequired(conn));
      break;
    case PROXY_SERVER:
      systemInfo.put(i, SystemInfoData.selectProxyServer(conn));
      break;
    case PROXY_PORT:
      systemInfo.put(i, SystemInfoData.selectProxyPort(conn));
      break;
    case ACTIVITY_RATE:
      systemInfo.put(i, getActivityRate(conn));
      break;
    case COMPLEXITY_RATE:
      systemInfo.put(i, getComplexityRate(conn));
      break;
    case OPERATING_SYSTEM:
      systemInfo.put(i, System.getProperty("os.name"));
      break;
    case OPERATING_SYSTEM_VERSION:
      systemInfo.put(i, System.getProperty("os.version"));
      break;
    case JAVA_VERSION:
      systemInfo.put(i, System.getProperty("java.version"));
      break;
    }
  }

  private final static String getSystemIdentifier(ConnectionProvider conn) throws ServletException {
    validateConnection(conn);
    String systemIdentifier = SystemInfoData.selectSystemIdentifier(conn);
    if (systemIdentifier == null || systemIdentifier.equals("")) {
      systemIdentifier = UUID.randomUUID().toString();
      SystemInfoData.updateSystemIdentifier(conn, systemIdentifier);
    }
    return systemIdentifier;
  }

  private final static String getDatabaseVersion(ConnectionProvider conn) throws ServletException {
    validateConnection(conn);
    if (systemInfo.get(Item.DATABASE) == null) {
      load(Item.DATABASE, conn);
    }
    String database = systemInfo.get(Item.DATABASE);
    String databaseVersion = null;
    if ("ORACLE".equals(database)) {
      databaseVersion = getVersion(SystemInfoData.selectOracleVersion(conn));
    } else {
      databaseVersion = SystemInfoData.selectPostregresVersion(conn);
    }
    return databaseVersion;
  }

  /**
   * Runs a native command to try and locate the user's web server version. Tests all combinations
   * of paths + commands.
   * 
   * Currently only checks for Apache.
   * 
   * @param conn
   * @throws ServletException
   */
  private final static String[] getWebserver(ConnectionProvider conn) {
    List<String> commands = new ArrayList<String>();
    String[] paths = { "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin",
        "/bin" };
    String[] execs = { "httpd", "apache", "apache2" };
    for (String path : paths) {
      for (String exec : execs) {
        commands.add(path + "/" + exec);
      }
    }
    commands.addAll(Arrays.asList(execs));
    for (String command : commands) {
      try {
        Process process = new ProcessBuilder(command, "-v").start();
        InputStream is = process.getInputStream();
        InputStreamReader isr = new InputStreamReader(is);
        BufferedReader br = new BufferedReader(isr);

        StringBuilder sb = new StringBuilder();
        String line;

        while ((line = br.readLine()) != null) {
          sb.append(line);
        }
        Pattern pattern = Pattern.compile("Apache/((\\d+\\.)+)\\d+");
        Matcher matcher = pattern.matcher(sb.toString());
        if (matcher.find()) {
          String s = matcher.group();
          return s.split("/");
        }
      } catch (IOException e) {
        // OK. We'll probably get a lot of these.
      }
    }
    return new String[] { "", "" };
  }

  /**
   * Returns the activity rate of the system. Range: 0..............1.- Inactive 1-100..........2.-
   * Low 101-500........3.- Medium 500-1000.......4.- High 1001 or more...5.- Very High
   * 
   * @param data
   * @return
   * @throws ServletException
   */
  private final static String getActivityRate(ConnectionProvider conn) throws ServletException {
    String result = null;
    int activityRate = Integer.valueOf(SystemInfoData.selectActivityRate(conn));
    if (activityRate == 0) {
      result = "1";
    } else if (activityRate > 0 && activityRate < 101) {
      result = "2";
    } else if (activityRate > 100 && activityRate < 501) {
      result = "3";
    } else if (activityRate > 500 && activityRate < 1001) {
      result = "4";
    } else if (activityRate > 1001) {
      result = "5";
    }
    return result;
  }

  /**
   * Returns the complexity rate of the system Range: 0-2 ............1.- Low 3-6.............2.-
   * Medium 7 or more.......3.- High
   * 
   * @param data
   * @return
   * @throws ServletException
   */
  private final static String getComplexityRate(ConnectionProvider conn) throws ServletException {
    String result = null;
    int complexityRate = Integer.valueOf(SystemInfoData.selectComplexityRate(conn));
    if (complexityRate > 0 && complexityRate < 3) {
      result = "1";
    } else if (complexityRate > 2 && complexityRate < 7) {
      result = "2";
    } else if (complexityRate > 7) {
      result = "3";
    }
    return result;
  }

  private static boolean validateConnection(ConnectionProvider conn) throws ServletException {
    if (conn == null) {
      throw new ServletException("Invalid database connection provided.");
    }
    return true;
  }

  /**
   * @return the all systemInfo properties
   */
  public static Properties getSystemInfo() {
    Properties props = new Properties();
    if (systemInfo == null) {
      return props;
    }
    for (Map.Entry<Item, String> entry : systemInfo.entrySet()) {
      String key = entry.getKey().getLabel();
      String value = entry.getValue();
      props.setProperty(key, value);
    }
    return props;
  }

  /**
   * Returns the string representation of a numerical version from a longer string. For example,
   * given the string: 'Apache Ant version 1.7.0 compiled on August 29 2007' getVersion() will
   * return '1.7.0'
   * 
   * @param str
   * @return the string representation of a numerical version from a longer string.
   */
  private static String getVersion(String str) {
    String version = "";
    if (str == null)
      return "";
    Pattern pattern = Pattern.compile("((\\d+\\.)+)\\d+");
    Matcher matcher = pattern.matcher(str);
    if (matcher.find()) {
      version = matcher.group();
    }
    return version;
  }

  /**
   * @param item
   * @return the systemInfo of the passed item
   */
  public static String get(Item item) {
    return systemInfo.get(item);
  }

  public enum Item {
    SYSTEM_IDENTIFIER("systemIdentifier"), OPERATING_SYSTEM("os"), OPERATING_SYSTEM_VERSION(
        "osVersion"), DATABASE("db"), DATABASE_VERSION("dbVersion"), WEBSERVER("webserver"), WEBSERVER_VERSION(
        "webserverVersion"), SERVLET_CONTAINER("servletContainer"), SERVLET_CONTAINER_VERSION(
        "servletContainerVersion"), ANT_VERSION("antVersion"), OB_VERSION("obVersion"), OB_INSTALL_MODE(
        "obInstallMode"), CODE_REVISION("codeRevision"), NUM_REGISTERED_USERS("numRegisteredUsers"), ISHEARTBEATACTIVE(
        "isheartbeatactive"), ISPROXYREQUIRED("isproxyrequired"), PROXY_SERVER("proxyServer"), PROXY_PORT(
        "proxyPort"), ACTIVITY_RATE("activityRate"), COMPLEXITY_RATE("complexityRate"), JAVA_VERSION(
        "javaVersion");

    private String label;

    private Item(String label) {
      this.label = label;
    }

    private String getLabel() {
      return label;
    }
  }

}
