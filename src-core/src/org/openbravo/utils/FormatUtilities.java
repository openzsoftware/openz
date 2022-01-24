/*
 ************************************************************************************
 * Copyright (C) 2001-2008 Openbravo S.L.
 * Licensed under the Apache Software License version 2.0
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to  in writing,  software  distributed
 * under the License is distributed  on  an  "AS IS"  BASIS,  WITHOUT  WARRANTIES  OR
 * CONDITIONS OF ANY KIND, either  express  or  implied.  See  the  License  for  the
 * specific language governing permissions and limitations under the License.
 *
 * Contributor:  Stefan Zimmermann, 01/2011, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
 *               added Padding Methods
 ************************************************************************************
 */
package org.openbravo.utils;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
//import org.apache.commons.text.StringEscapeUtils;

public class FormatUtilities {
  static Logger log4j = Logger.getLogger(FormatUtilities.class);

  public static String truncate(String s, int i) {
    if (s == null || s.length() == 0)
      return "";
    if (i < s.length())
      s = s.substring(0, i) + "...";
    return s;
  }

  public static String replaceTildes(String strIni) {
    // Delete tilde characters
    return strIni.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace(
        'ú', 'u').replace('Á', 'A').replace('É', 'E').replace('Í', 'I').replace('Ó', 'O').replace(
        'Ú', 'U');
  }

  private static final char[] delChars = { '-', '/', '#', ' ', '&', ',', '(', ')' };

  public static String replace(String strIni) {
    // delete characters: " ","&",","
    String result = replaceTildes(Replace.delChars(strIni, delChars));
    return result;
  }

  public static String replaceJS(String strIni) {
    return replaceJS(strIni, true);
  }

  public static String replaceJS(String strIni, boolean isUnderQuotes) {
    return Replace.replace(Replace.replace(Replace.replace(Replace.replace(strIni, "'",
        (isUnderQuotes ? "\\'" : "&#039;")), "\"", "\\\""), "\n", "\\n"), "\r", "\\r");
  }

  public static String sha1Base64(String text) throws ServletException {
    if (text == null || text.trim().equals(""))
      return "";
    String result = text;
    result = CryptoSHA1BASE64.hash(text);
    return result;
  }

  public static String encryptDecrypt(String text, boolean encrypt) throws ServletException {
    if (text == null || text.trim().equals(""))
      return "";
    String result = text;
    if (encrypt)
      result = CryptoUtility.encrypt(text);
    else
      result = CryptoUtility.decrypt(text);
    return result;
  }

  public static String sanitizeInput(String text) {
   // String sanitized = StringEscapeUtils.escapeHtml4(text);
    String sanitized = text;
    String[] tags = { "<[/]?applet>", "<[/]?body>", "<[/]?embed>", "<[/]?frame>", "<[/]?script>",
        "<[/]?frameset>", "<[/]?html>", "<[/]?iframe>", "<[/]?img>", "<[/]?style>", "<[/]?layer>",
        "<[/]?link>", "<[/]?ilayer>", "<[/]?meta>", "<[/]?object>" };
    for (int i = 0; i < tags.length; i++)
      sanitized = sanitized.replaceAll("(?i)" + tags[i], "");
    return sanitized;
  }

  public static String[] sanitizeInput(String[] text) {
    for (int i = 0; i < text.length; i++)
      text[i] = sanitizeInput(text[i]);
    return text;
  }
  public static String padRight(String s, int n) {
    return String.format("%1$-" + n + "s", s);
  }

  public static String padLeft(String s, int n) {
    return String.format("%1$#" + n + "s", s);
  }
}
