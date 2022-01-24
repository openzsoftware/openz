/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.zsoft.ecommerce.businesspartner;
import org.zsoft.ecommerce.*;

public class Location {
  private String id;
  private String businessPartnerId;
  private String address1;
  private String address2;
  private String city;
  private String postal;
  private String region;
  private String country;
  private Boolean isinvoicetolocation=false;
  private Boolean isdreliverytolocation=false;
  private String uidnumber;

  public Location() {
  }

  public String getId() {
    return id;
  }

  public void setId(String value) {
    id = value;
  }


  public String getBusinessPartnerId() {
    return businessPartnerId;
  }

  public void setBusinessPartnerId(String value) {
    businessPartnerId = value;
  }

  public String getAddress1() {
    return address1;
  }

  public void setAddress1(String value) {
    address1 = value;
  }

  public String getAddress2() {
    return address2;
  }

  public void setAddress2(String value) {
    address2 = value;
  }

  public String getCity() {
    return city;
  }

  public void setCity(String value) {
    city = value;
  }

  public Boolean getIsinvoicetolocation() {
    return isinvoicetolocation;
  }

  public void setIsinvoicetolocation(Boolean value) {
    isinvoicetolocation = value;
  }

  public Boolean getIsdreliverytolocation() {
    return isdreliverytolocation;
  }

  public void setIsdreliverytolocation(Boolean value) {
    isdreliverytolocation = value;
  }

  public String getUidnumber() {
    return uidnumber;
  }

  public void setUidnumber(String value) {
    uidnumber = value;
  }
  public String getPostal() {
    return postal;
  }

  public void setPostal(String value) {
    postal = value;
  }

  public String getRegion() {
    return region;
  }

  public void setRegion(String value) {
    region = value;
  }

  public String getCountry() {
    return country;
  }

  public void setCountry(String value) {
    country = value;
  }
}
