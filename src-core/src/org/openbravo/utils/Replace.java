/*
 ************************************************************************************
 * Copyright (C) 2001-2006 Openbravo S.L.
 * Licensed under the Apache Software License version 2.0
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to  in writing,  software  distributed
 * under the License is distributed  on  an  "AS IS"  BASIS,  WITHOUT  WARRANTIES  OR
 * CONDITIONS OF ANY KIND, either  express  or  implied.  See  the  License  for  the
 * specific language governing permissions and limitations under the License.
 ************************************************************************************
 */
package org.openbravo.utils;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

//import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang.StringUtils;

public class Replace {
  
public static void replace(StringBuilder sb, String strReplaceWhat, String strReplaceWith) {
  if (sb == null || strReplaceWhat == null)
    return;
  if (strReplaceWith==null)
    strReplaceWith="";
  int index = sb.indexOf(strReplaceWhat);
  while (index != -1)
  {
      sb.replace(index, index + strReplaceWhat.length(), strReplaceWith);
      index += strReplaceWith.length(); // Move to the end of the replacement
      index = sb.indexOf(strReplaceWhat, index);
  }
}

  public static String replace(String strInicial, String strReplaceWhat, String strReplaceWith) {
    if (strInicial == null || strReplaceWhat == null)
      return strInicial;
    /*
    String toreplace="";
    if (strInicial == null || strInicial.equals(""))
      return strInicial;
    else if (strReplaceWhat == null || strReplaceWhat.equals(""))
      return strInicial;
    if (strReplaceWith!=null)
      toreplace=strReplaceWith;
    */
    if (strReplaceWith==null)
      strReplaceWith="";
    //return strInicial.replace(strReplaceWhat, strReplaceWith);
    return StringUtils.replace(strInicial,  strReplaceWhat,  strReplaceWith);
   
    /*
    if (strInicial == null || strInicial.equals(""))
      return strInicial;
    else if (strReplaceWhat == null || strReplaceWhat.equals(""))
      return strInicial;
    else if (strReplaceWith == null)
      strReplaceWith = "";
    StringBuffer strFinal = new StringBuffer("");
    do {
      pos = strInicial.indexOf(strReplaceWhat, index);
      if (pos != -1) {
        strFinal.append(strInicial.substring(index, pos) + strReplaceWith);
        index = pos + strReplaceWhat.length();
      } else {
        strFinal.append(strInicial.substring(index));
      }
    } while (index < strInicial.length() && pos != -1);
    return strFinal.toString();
    */
  }

  public static String delChars(String str, char[] delChars) {
    int length = str.length();
    int charLength = delChars.length;
    StringBuilder result = new StringBuilder(length);

    for (int i = 0; i < length; i++) {
      char current = str.charAt(i);
      boolean del = false;
      for (int j = 0; j < charLength; j++) {
        if (current == delChars[j]) {
          del = true;
          break;
        }
      }
      if (!del) {
        result.append(current);
      }
    }
    return result.toString();
  }

}// End of class
