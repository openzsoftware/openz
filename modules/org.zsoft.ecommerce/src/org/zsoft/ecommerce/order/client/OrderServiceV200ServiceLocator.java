/**
 * OrderServiceV100ServiceLocator.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.zsoft.ecommerce.order.client;

public class OrderServiceV200ServiceLocator extends org.apache.axis.client.Service implements OrderServiceV200Service {

    public OrderServiceV200ServiceLocator() {
    }


    public OrderServiceV200ServiceLocator(org.apache.axis.EngineConfiguration config) {
        super(config);
    }

    public OrderServiceV200ServiceLocator(java.lang.String wsdlLoc, javax.xml.namespace.QName sName) throws javax.xml.rpc.ServiceException {
        super(wsdlLoc, sName);
    }

    // Use to get a proxy class for OrderServiceV200
    private java.lang.String OrderServiceV200_address = "http://localhost:8080/openz/services/OrderServiceV200";

    public java.lang.String getOrderServiceV200Address() {
        return OrderServiceV200_address;
    }

    // The WSDD service name defaults to the port name.
    private java.lang.String OrderServiceV200WSDDServiceName = "OrderServiceV200";

    public java.lang.String getOrderServiceV200WSDDServiceName() {
        return OrderServiceV200WSDDServiceName;
    }

    public void setOrderServiceV200WSDDServiceName(java.lang.String name) {
        OrderServiceV200WSDDServiceName = name;
    }

    public OrderServiceV200 getOrderServiceV200() throws javax.xml.rpc.ServiceException {
       java.net.URL endpoint;
        try {
            endpoint = new java.net.URL(OrderServiceV200_address);
        }
        catch (java.net.MalformedURLException e) {
            throw new javax.xml.rpc.ServiceException(e);
        }
        return getOrderServiceV200(endpoint);
    }

    public OrderServiceV200 getOrderServiceV200(java.net.URL portAddress) throws javax.xml.rpc.ServiceException {
        try {
            OrderServiceV200SoapBindingStub _stub = new OrderServiceV200SoapBindingStub(portAddress, this);
            _stub.setPortName(getOrderServiceV200WSDDServiceName());
            return _stub;
        }
        catch (org.apache.axis.AxisFault e) {
            return null;
        }
    }

    public void setOrderServiceV200EndpointAddress(java.lang.String address) {
        OrderServiceV200_address = address;
    }

    /**
     * For the given interface, get the stub implementation.
     * If this service has no port for the given interface,
     * then ServiceException is thrown.
     */
    public java.rmi.Remote getPort(Class serviceEndpointInterface) throws javax.xml.rpc.ServiceException {
        try {
            if (OrderServiceV200.class.isAssignableFrom(serviceEndpointInterface)) {
                OrderServiceV200SoapBindingStub _stub = new OrderServiceV200SoapBindingStub(new java.net.URL(OrderServiceV200_address), this);
                _stub.setPortName(getOrderServiceV200WSDDServiceName());
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
        if ("OrderServiceV200".equals(inputPortName)) {
            return getOrderServiceV200();
        }
        else  {
            java.rmi.Remote _stub = getPort(serviceEndpointInterface);
            ((org.apache.axis.client.Stub) _stub).setPortName(portName);
            return _stub;
        }
    }

    public javax.xml.namespace.QName getServiceName() {
        return new javax.xml.namespace.QName("http://localhost:8080/openz/services/OrderServiceV200", "OrderServiceV200Service");
    }

    private java.util.HashSet ports = null;

    public java.util.Iterator getPorts() {
        if (ports == null) {
            ports = new java.util.HashSet();
            ports.add(new javax.xml.namespace.QName("http://localhost:8080/openz/services/OrderServiceV200", "OrderServiceV200"));
        }
        return ports.iterator();
    }

    /**
    * Set the endpoint address for the specified port name.
    */
    public void setEndpointAddress(java.lang.String portName, java.lang.String address) throws javax.xml.rpc.ServiceException {
        
if ("OrderServiceV200".equals(portName)) {
            setOrderServiceV200EndpointAddress(address);
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
