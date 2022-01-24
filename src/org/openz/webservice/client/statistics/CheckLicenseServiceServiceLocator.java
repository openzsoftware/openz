/**
 * CheckLicenseServiceServiceLocator.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.openz.webservice.client.statistics;

public class CheckLicenseServiceServiceLocator extends org.apache.axis.client.Service implements org.openz.webservice.client.statistics.CheckLicenseServiceService {

    public CheckLicenseServiceServiceLocator() {
    }


    public CheckLicenseServiceServiceLocator(org.apache.axis.EngineConfiguration config) {
        super(config);
    }

    public CheckLicenseServiceServiceLocator(java.lang.String wsdlLoc, javax.xml.namespace.QName sName) throws javax.xml.rpc.ServiceException {
        super(wsdlLoc, sName);
    }

    // Use to get a proxy class for CheckLicenseService
    private java.lang.String CheckLicenseService_address = "https://openzdatahub.de/openz/services/CheckLicenseService";

    public java.lang.String getCheckLicenseServiceAddress() {
        return CheckLicenseService_address;
    }

    // The WSDD service name defaults to the port name.
    private java.lang.String CheckLicenseServiceWSDDServiceName = "CheckLicenseService";

    public java.lang.String getCheckLicenseServiceWSDDServiceName() {
        return CheckLicenseServiceWSDDServiceName;
    }

    public void setCheckLicenseServiceWSDDServiceName(java.lang.String name) {
        CheckLicenseServiceWSDDServiceName = name;
    }

    public org.openz.webservice.client.statistics.CheckLicenseService getCheckLicenseService() throws javax.xml.rpc.ServiceException {
       java.net.URL endpoint;
        try {
            endpoint = new java.net.URL(CheckLicenseService_address);
        }
        catch (java.net.MalformedURLException e) {
            throw new javax.xml.rpc.ServiceException(e);
        }
        return getCheckLicenseService(endpoint);
    }

    public org.openz.webservice.client.statistics.CheckLicenseService getCheckLicenseService(java.net.URL portAddress) throws javax.xml.rpc.ServiceException {
        try {
            org.openz.webservice.client.statistics.CheckLicenseServiceSoapBindingStub _stub = new org.openz.webservice.client.statistics.CheckLicenseServiceSoapBindingStub(portAddress, this);
            _stub.setPortName(getCheckLicenseServiceWSDDServiceName());
            return _stub;
        }
        catch (org.apache.axis.AxisFault e) {
            return null;
        }
    }

    public void setCheckLicenseServiceEndpointAddress(java.lang.String address) {
        CheckLicenseService_address = address;
    }

    /**
     * For the given interface, get the stub implementation.
     * If this service has no port for the given interface,
     * then ServiceException is thrown.
     */
    public java.rmi.Remote getPort(Class serviceEndpointInterface) throws javax.xml.rpc.ServiceException {
        try {
            if (org.openz.webservice.client.statistics.CheckLicenseService.class.isAssignableFrom(serviceEndpointInterface)) {
                org.openz.webservice.client.statistics.CheckLicenseServiceSoapBindingStub _stub = new org.openz.webservice.client.statistics.CheckLicenseServiceSoapBindingStub(new java.net.URL(CheckLicenseService_address), this);
                _stub.setPortName(getCheckLicenseServiceWSDDServiceName());
                return _stub;
            }
        }
        catch (java.lang.Throwable t) {
            throw new javax.xml.rpc.ServiceException(t);
        }
        throw new javax.xml.rpc.ServiceException("There is no stub implementation for the interface:  " + (serviceEndpointInterface == null ? "null" : serviceEndpointInterface.getName()));
    }

    /**
     * For the given interface, get the stub implementation.
     * If this service has no port for the given interface,
     * then ServiceException is thrown.
     */
    public java.rmi.Remote getPort(javax.xml.namespace.QName portName, Class serviceEndpointInterface) throws javax.xml.rpc.ServiceException {
        if (portName == null) {
            return getPort(serviceEndpointInterface);
        }
        java.lang.String inputPortName = portName.getLocalPart();
        if ("CheckLicenseService".equals(inputPortName)) {
            return getCheckLicenseService();
        }
        else  {
            java.rmi.Remote _stub = getPort(serviceEndpointInterface);
            ((org.apache.axis.client.Stub) _stub).setPortName(portName);
            return _stub;
        }
    }

    public javax.xml.namespace.QName getServiceName() {
        return new javax.xml.namespace.QName("https://openzdatahub.de/openz/services/CheckLicenseService", "CheckLicenseServiceService");
    }

    private java.util.HashSet ports = null;

    public java.util.Iterator getPorts() {
        if (ports == null) {
            ports = new java.util.HashSet();
            ports.add(new javax.xml.namespace.QName("https://openzdatahub.de/openz/services/CheckLicenseService", "CheckLicenseService"));
        }
        return ports.iterator();
    }

    /**
    * Set the endpoint address for the specified port name.
    */
    public void setEndpointAddress(java.lang.String portName, java.lang.String address) throws javax.xml.rpc.ServiceException {
        
if ("CheckLicenseService".equals(portName)) {
            setCheckLicenseServiceEndpointAddress(address);
        }
        else 
{ // Unknown Port Name
            throw new javax.xml.rpc.ServiceException(" Cannot set Endpoint Address for Unknown Port" + portName);
        }
    }

    /**
    * Set the endpoint address for the specified port name.
    */
    public void setEndpointAddress(javax.xml.namespace.QName portName, java.lang.String address) throws javax.xml.rpc.ServiceException {
        setEndpointAddress(portName.getLocalPart(), address);
    }

}
