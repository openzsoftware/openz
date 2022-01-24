/**
 * OrderServiceV100.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.zsoft.ecommerce.order.client;



public interface OrderServiceV200 extends java.rmi.Remote {
    public OrderResponse submitOrder(java.lang.String orgId, java.lang.String username, java.lang.String password, OrderV200 porder) throws java.rmi.RemoteException;
    public OrderV200 getOrder(java.lang.String orgId, java.lang.String username, java.lang.String password, java.lang.String cOrderId) throws java.rmi.RemoteException;
}