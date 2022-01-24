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

public class BusinessPartnerV2 {
  private String id;
  // In This Context Client ID means The ORG_ID in the Openbravo-System
  private String orgId="";
  private String name="";
  private String searchKey="";
  private String description="";
  private String uidnumber="";
  private Boolean isblocked=null;// 
  private Boolean complete=null;
  private Boolean customer=null;
  private Boolean vendor=null;
  private String message="";
  private String bpgroup="";
  private Location[] locations=null;
  private Contact[] contacts=null;
  private Payterm[] payterms=null;

  public BusinessPartnerV2() {
  }
  public String getBpGroup() {
    return bpgroup;
  }

  public void setBpGroup(String value) {
    bpgroup = value;
  }
  public String getId() {
    return id;
  }

  public void setId(String value) {
    id = value;
  }

  public String getorgId() {
    return orgId;
  }

  public void setorgId(String value) {
    orgId = value;
  }

  public String getName() {
    return name;
  }

  public void setDescription(String value) {
    description = value;
  }

  public String getDescription() {
    return description;
  }
  public String getUidnumber() {
    return uidnumber;
  }

  public void setUidnumber(String value) {
    uidnumber = value;
  }

  public void setIsblocked(Boolean value) {
    isblocked = value;
  }

  public Boolean getIsblocked() {
    return isblocked;
  }
  public void setName(String value) {
    name = value;
  }

  public String getSearchKey() {
    return searchKey;
  }

  public void setSearchKey(String value) {
    searchKey = value;
  }

  public Location[] getLocations() {
    return locations;
  }

  public void setLocations(Location[] value) {
    locations = value;
  }
  
  public Payterm[] getPayterms() {
    return payterms;
  }

  public void setPayterms(Payterm[] value) {
    payterms = value;
  }
  public Contact[] getContacts() {
    return contacts;
  }

  public void setContacts(Contact[] value) {
    contacts = value;
  }

  public Boolean isComplete() {
    return complete;
  }

  public void setComplete(Boolean value) {
    complete = value;
  }

  public Boolean isCustomer() {
    return customer;
  }

  public void setCustomer(Boolean value) {
    customer = value;
  }

  public Boolean isVendor() {
    return vendor;
  }

  public void setVendor(Boolean value) {
    vendor = value;
  }
  
  public String getMessage() {
    return message;
  }

  public void setMessage(String value) {
    message = value;
  }
}
