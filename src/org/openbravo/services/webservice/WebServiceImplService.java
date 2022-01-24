/**
 * WebServiceImplService.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.openbravo.services.webservice;

public interface WebServiceImplService extends javax.xml.rpc.Service {
    public java.lang.String getWebServiceAddress();

    public org.openbravo.services.webservice.WebServiceImpl getWebService() throws javax.xml.rpc.ServiceException;

    public org.openbravo.services.webservice.WebServiceImpl getWebService(java.net.URL portAddress) throws javax.xml.rpc.ServiceException;
}
