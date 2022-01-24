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

import java.sql.Connection;

import org.apache.log4j.Logger;
import org.zsoft.ecommerce.*;

public class BusinessPartnerServiceV2 extends WebService  {
  private static Logger log4j = Logger.getLogger(BusinessPartnerServiceV2.class); 

  public CustomerV2[] getCustomers(String orgId, String username, String password) throws Exception {

    CustomerV2[] customers = null;
    if (!access(username, password,orgId)) {
      if (log4j.isDebugEnabled())
        log4j.debug("Access denied for user: " + username);
      throw new Exception("Access denied for user: " + username); 
    }
    try {

      WebServicesCustomerData[] data = WebServicesCustomerData.select(pool, orgId);

      customers = new CustomerV2[data.length];

      for (int i = 0; i < data.length; i++) {
        customers[i] = new CustomerV2();
        customers[i].setId(data[i].id);
        customers[i].setorgId(data[i].orgId);
        customers[i].setName(data[i].name);
        customers[i].setDescription(data[i].description);
        customers[i].setSearchKey(data[i].searchkey);
        customers[i].setBpGroup(data[i].bpgroup);
        customers[i].setComplete(false);
        customers[i].setIsblocked(data[i].isblocked.equals("Y") ? true : false);
      }
    } catch (Exception e) {
      log4j.error(e.getMessage());
      throw new Exception("Exception in Webservice: " + e.getMessage()); 
    } finally {
      destroyPool();
    }
    return customers;
  }
  public CustomerV2 getCustomer(String orgId, String name, String searchKey, String username,
            String password) throws Exception {
       // In This Context Client ID means The ORG_ID in the Openbravo-System
          CustomerV2 customer = new CustomerV2();
          if (!access(username, password,orgId)) {
            if (log4j.isDebugEnabled())
              log4j.debug("Access denied for user: " + username);
              customer.setMessage("Access denied for user: " + username);
              throw new Exception("Access denied for user: " + username); 
          }
          try {
      
            WebServicesCustomerData[] data = WebServicesCustomerData.selectCustomer(pool, orgId,
               (name == null ? "" : name), (searchKey == null ? "" : searchKey));
      
            if (data.length >= 1) {
              customer.setId(data[0].id);
              customer.setorgId(data[0].orgId);
              customer.setName(data[0].name);
              customer.setSearchKey(data[0].searchkey);
              customer.setBpGroup(data[0].bpgroup);
              customer.setComplete(false);
            } else {
              customer.setMessage("No Customer found for this Request.");
            }
          } catch (Exception e) {
            log4j.error(e.getMessage());
            throw new Exception("Exception in Webservice: " + e.getMessage()); 
          } finally {
            destroyPool();
          }
          return customer;
        }

  public CustomerV2 getCustomer(String customerId, String username, String password)  throws Exception {
 // In This Context Client ID means The ORG_ID in the Openbravo-System
    CustomerV2 customer = new CustomerV2();
    Location[] locations = null;
    Contact[] contacts = null;
    Payterm[] payterms = null;
    
    try {

      WebServicesCustomerData[] data = WebServicesCustomerData.selectCustomerById(pool, customerId);
      
      if (data.length > 0) {
        if (!access(username, password,data[0].orgId)) {
          if (log4j.isDebugEnabled())
            log4j.debug("Access denied for user: " + username);
            customer.setMessage("Access denied for user: " + username);
            destroyPool();
            throw new Exception("Access denied for user: " + username); 
        }
        customer.setId(data[0].id);
        customer.setorgId(data[0].orgId);
        customer.setName(data[0].name);
        customer.setSearchKey(data[0].searchkey);
        customer.setBpGroup(data[0].bpgroup);
        customer.setIsblocked(data[0].isblocked.equals("Y") ? true : false);
        String uid=WebServicesCustomerData.getCustomerUID(pool, customerId);
        customer.setUidnumber(uid);
        WebServicesAddressData[] addata = WebServicesAddressData.select(pool, customerId);
        locations = new Location[addata.length];
        for (int i = 0; i < addata.length; i++) {
          if (i==0) locations = new Location[addata.length];
          locations[i]=new Location();
          locations[i].setAddress1(addata[i].address1);
          locations[i].setAddress2(addata[i].address2);
          locations[i].setBusinessPartnerId(customerId);
          locations[i].setCity(addata[i].city);
          locations[i].setCountry(addata[i].country);
          locations[i].setId(addata[i].cLocationId);
          locations[i].setPostal(addata[i].postal);
          locations[i].setRegion(addata[i].region);
          locations[i].setIsdreliverytolocation(addata[i].isshipto.equals("Y") ? true : false);
          locations[i].setIsinvoicetolocation(addata[i].isbillto.equals("Y") ? true : false);
          locations[i].setUidnumber(addata[i].uidnumber);
        }
        if (addata.length>0) {
          customer.setLocations(locations);
        }
        WebServicesContactData[] condata = WebServicesContactData.selectContacts(pool, customerId);
        for (int i = 0; i < condata.length; i++) {
          if (i==0) contacts = new Contact[condata.length]; 
          contacts[i]=new Contact();
          contacts[i].setBusinessPartnerId(customerId);
          contacts[i].setEmail(condata[i].email);
          contacts[i].setFax(condata[i].fax);
          contacts[i].setFirstName(condata[i].firstname);
          contacts[i].setLastName(condata[i].lastname);
          contacts[i].setName(condata[i].name);
          contacts[i].setPhone(condata[i].phone);
          contacts[i].setPhone2(condata[i].phone2);
          contacts[i].setGreeting(condata[i].greeting);
          contacts[i].setId(condata[i].adUserId);
        }
        if (condata.length>0) {
          customer.setContacts(contacts);
        }
        PaytermsData[] pdata = PaytermsData.select(pool, customerId, "");
        for (int i = 0; i < pdata.length; i++) {
          if (i==0) payterms = new Payterm[pdata.length]; 
          payterms[i]=new Payterm();
          payterms[i].setBusinessPartnerId(customerId);
          payterms[i].setPayterm(pdata[i].name);
        }
        if (pdata.length>0) {
          customer.setPayterms(payterms);
        }
        customer.setComplete(true);
      }
      else {
        // No Data found
        customer.setMessage("No Customer found for this Request.");
      }
    } catch (Exception e) {
      log4j.error(e.getMessage());
      throw new Exception("Exception in Webservice: " + e.getMessage()); 
    } finally {
      destroyPool();
    }
    return customer;
  }

 

  public CustomerV2 updateCustomer(String orgId, CustomerV2 customer, String username, String password)   throws Exception  {
    String updated="ERR";
    String errm="OK";
    CustomerV2 cust = new CustomerV2();
    if (!access(username, password,orgId)) {
      if (log4j.isDebugEnabled())
        log4j.debug("Access denied for user: " + username);
        customer.setMessage("Access denied for user: " + username);
        throw new Exception("Access denied for user: " + username); 
    }
    Connection con=pool.getTransactionConnection();
    con.setAutoCommit(false);
    try {
      updated = WebServicesCustomerData.updateCustomer(con,pool, customer.getId(),customer.getSearchKey(), customer.getName(),username,orgId,customer.getBpGroup());
      String corgid;
      String custid;
      if (customer.getId()==null)
        custid=updated;
      else
        if (customer.getId().equals("")) 
        custid=updated;
      else
        custid=customer.getId();
      if (customer.getorgId().equals(""))
        corgid=orgId;
      else
        corgid=customer.getorgId();
      if (updated.contains("ERR"))
        //Raise...
        throw new Exception("Error Updating Customer: " + updated); 
      // Request updates PaymentMethods
      if (customer.getPayterms()!=null) {
        if (customer.getPayterms().length>0){
            WebServicesCustomerData.deleteECPaymentMethods(con,pool, custid);
            Payterm[] payterms = new Payterm[customer.getPayterms().length];
            payterms=customer.getPayterms();
            for (int i = 0; i < customer.getPayterms().length; i++) {
              // Translate to OZ-Intzernal List-Value
              String ecpaymentmethod=null;
              if (payterms[i].getPayterm().equals("Amex")) 
                ecpaymentmethod="A";
              if (payterms[i].getPayterm().equals("Visa")) 
                ecpaymentmethod="V";
              if (payterms[i].getPayterm().equals("Mastercard")) 
                ecpaymentmethod="M";
              if (payterms[i].getPayterm().equals("Invoice")) 
                ecpaymentmethod="I";
              if (payterms[i].getPayterm().equals("Bank Collection")) 
                ecpaymentmethod="BC";
              if (payterms[i].getPayterm().equals("Bank Collection (manual)")) 
                ecpaymentmethod="BCM";
              if (payterms[i].getPayterm().equals("Prepaid")) 
                ecpaymentmethod="P";
              if (payterms[i].getPayterm().equals("Paypal")) 
                ecpaymentmethod="PP";
              if (payterms[i].getPayterm().equals("Cash on Delivery")) 
                ecpaymentmethod="C";
                    
              int dummy = WebServicesCustomerData.insertECPaymentMethod(con,pool,clientId, corgid,
                          userId,custid,ecpaymentmethod);
            }
        }
      }
    } catch (Exception e) {
      errm=e.getMessage();
      log4j.error(errm);
      con.rollback();
      throw new Exception("Exception in Webservice: " + e.getMessage()); 
    } finally {
      pool.releaseCommitConnection(con);
      con=null;
      destroyPool();
    }
    if (updated.equals("ERR")) {
      cust.setMessage("ERROR: Update Failed: Database Error." + errm);
      throw new Exception("ERROR: Update Failed: Database Error." + errm); 
    } else if (updated.equals("UPDATED")) {
      cust = getCustomer(customer.getId(),username,password);
      cust.setMessage("Update Successful");
    } else {
      cust = getCustomer(updated,username,password);
      cust.setMessage("Insert Successful. New Customer created.");
    }
    return cust;
  }

  

  public CustomerV2 updateAddress(Location addr, String username, String password)  throws Exception  {
    String updated = "ERR";
    String errm="OK";
    CustomerV2 cust = new CustomerV2();
    cust = getCustomer(addr.getBusinessPartnerId(),username,password);
    if (!access(username, password,cust.getorgId())) {
      if (log4j.isDebugEnabled())
        log4j.debug("Access denied for user: " + username);
      throw new Exception("Access denied for user: " + username); 
    }
    try {
    updated = WebServicesAddressData.updateAddress(pool,addr.getBusinessPartnerId(),username,addr.getAddress1(),addr.getAddress2(),addr.getCity(),addr.getPostal(),
              addr.getCountry(),addr.getIsinvoicetolocation() ? "Y" : "N",addr.getIsdreliverytolocation() ? "Y" : "N",addr.getUidnumber(),addr.getId());
    } catch (Exception e) {
      errm=e.getMessage();
      log4j.error(errm);
      throw new Exception("Exception in Webservice: " + e.getMessage()); 
    } finally {
      destroyPool();
    }
    if (updated.equals("ERR")) {
      cust.setMessage("ERROR: Update Failed: Database Error." + errm);
      throw new Exception("ERROR: Update Failed: Database Error." + errm); 
    } else {
      cust = getCustomer(addr.getBusinessPartnerId(),username,password);
      cust.setMessage("Update Successful");
    }
    return cust;
  }



  public CustomerV2 updateContact(Contact cont, String username, String password)  throws Exception  {
    String updated = "ERR";
    String errm="OK";
    CustomerV2 cust = new CustomerV2();
    cust=getCustomer(cont.getBusinessPartnerId(),username,password);
    
    if (!access(username, password,cust.getorgId())) {
      if (log4j.isDebugEnabled())
        log4j.debug("Access denied for user: " + username);
      throw new Exception("Access denied for user: " + username); 
    }
    try {
      updated = WebServicesContactData.updateContact(pool, cont.getBusinessPartnerId(),username,cont.getFirstName(),cont.getLastName(),cont.getName(),cont.getEmail(),cont.getPhone(),cont.getPhone2(),cont.getFax(),cont.getGreeting(),cont.getId());
    } catch (Exception e) {
      errm=e.getMessage();
      log4j.error(errm);
      throw new Exception("Exception in Webservice: " + e.getMessage()); 
    } finally {
      destroyPool();
    }
    if (updated.equals("ERR")) {
      cust.setMessage("ERROR: Update Failed: Database Error." + errm);
      throw new Exception("ERROR: Update Failed: Database Error." + errm); 
    } else {
      cust=getCustomer(cont.getBusinessPartnerId(),username,password);
      cust.setMessage("Update Successful");
    }
    return cust;
  }

  
}
