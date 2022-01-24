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
 * All portions are Copyright (C) 2001-2006 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.wad.controls;

import java.util.Properties;

import org.openbravo.xmlEngine.XmlDocument;

public class WADHidden extends WADControl {

  public WADHidden() {
  }

  public WADHidden(String _columnname, String _columnnameInp, String _dataName, boolean isParameter) {
    setData("ColumnName", _columnname);
    setData("ColumnNameInp", _columnnameInp);
    setData("DataName", _dataName);
    setData("IsInData", (isParameter ? "N" : "Y"));
    initialize();
  }

  public WADHidden(Properties prop) {
    setInfo(prop);
    initialize();
  }

  public void initialize() {
    return;
  }

  public String toString() {
    XmlDocument xmlDocument = getReportEngine().readXmlTemplate(
        "org/openbravo/wad/controls/WADHidden").createXmlDocument();

    xmlDocument.setParameter("columnName", getData("ColumnName"));
    xmlDocument.setParameter("columnNameInp", getData("ColumnNameInp"));

    return replaceHTML(xmlDocument.print());
  }

  public String toLabel() {
    return "";
  }

  public String toXml() {
    String[] discard = { "sectionField" };
    if (getData("IsInData").equals("Y"))
      discard[0] = "sectionParameter";
    XmlDocument xmlDocument = getReportEngine().readXmlTemplate(
        "org/openbravo/wad/controls/WADHiddenXML", discard).createXmlDocument();

    xmlDocument.setParameter("columnName", getData("ColumnName"));
    return replaceHTML(xmlDocument.print());
  }

  public String toJava() {
    return "";
  }
}
