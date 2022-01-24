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

public class Contact {
  private String id;
  private String businessPartnerId;
  private String firstname;
  private String lastname;
  private String name;
  private String email;
  private String phone;
  private String phone2;
  private String fax;
  private String greeting;

  public Contact() {
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

  public String getFirstName() {
    return firstname;
  }

  public void setFirstName(String value) {
    firstname = value;
  }

  public String getLastName() {
    return lastname;
  }

  public void setLastName(String value) {
    lastname = value;
  }
  
  public String getName() {
    return name;
  }

  public void setName(String value) {
    name = value;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String value) {
    email = value;
  }

  public String getPhone() {
    return phone;
  }

  public void setPhone(String value) {
    phone = value;
  }

  public String getPhone2() {
    return phone2;
  }

  public void setPhone2(String value) {
    phone2 = value;
  }

  public String getFax() {
    return fax;
  }

  public void setFax(String value) {
    fax = value;
  }
  public String getGreeting() {
    return greeting;
  }

  public void setGreeting(String value) {
    greeting = value;
  }
}
