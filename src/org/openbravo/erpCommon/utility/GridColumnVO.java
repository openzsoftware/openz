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
 * All portions are Copyright (C) 2007-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.utility;

class GridColumnVO {
  private String title;
  private String dbName;
  private int width;
  private Class<?> fieldClass;
  private int precision;

  public GridColumnVO(String title, String dbName, int width, Class<?> fieldClass,int precision) {
    super();
    this.title = title;
    this.dbName = dbName;
    this.width = width;
    this.fieldClass = fieldClass;
    this.precision=precision;
  }

  public String getDbName() {
    return dbName;
  }

  public String getTitle() {
    return title;
  }

  public int getWidth() {
    return width;
  }
  
  public int getPrecision() {
    return precision;
  }

  public Class<?> getFieldClass() {
    return fieldClass;
  }

  public void setDbName(String dbName) {
    this.dbName = dbName;
  }

  public void setTitle(String title) {
    this.title = title;
  }

  public void setWidth(int width) {
    this.width = width;
  }

  public void setFieldClass(Class<?> fieldClass) {
    this.fieldClass = fieldClass;
  }
}
