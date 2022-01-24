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

package org.openbravo.erpCommon.ws.externalSales;

public class BPartner {
  private java.lang.String id;
  private java.lang.String name;
  private java.lang.String country;
  private java.lang.String region;
  private java.lang.String city;
  private java.lang.String postal;
  private java.lang.String address1;
  private java.lang.String address2;

  /** Creates a new instance of BPartner */
  public BPartner() {
  }

  public java.lang.String getId() {
    return id;
  }

  public void setId(java.lang.String id) {
    this.id = id;
  }

  public java.lang.String getName() {
    return name;
  }

  public void setName(java.lang.String name) {
    this.name = name;
  }

  public java.lang.String getCountry() {
    return country;
  }

  public void setCountry(java.lang.String country) {
    this.country = country;
  }

  public java.lang.String getRegion() {
    return region;
  }

  public void setRegion(java.lang.String region) {
    this.region = region;
  }

  public java.lang.String getCity() {
    return city;
  }

  public void setCity(java.lang.String city) {
    this.city = city;
  }

  public java.lang.String getPostal() {
    return postal;
  }

  public void setPostal(java.lang.String postal) {
    this.postal = postal;
  }

  public java.lang.String getAddress1() {
    return address1;
  }

  public void setAddress1(java.lang.String address1) {
    this.address1 = address1;
  }

  public java.lang.String getAddress2() {
    return address2;
  }

  public void setAddress2(java.lang.String address2) {
    this.address2 = address2;
  }
}
