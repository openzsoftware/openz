/**
 * OrderResponse.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.zsoft.ecommerce.order.client;

public class OrderResponse  implements java.io.Serializable {
    private java.lang.String COrderId;

    private java.lang.String docstatus;

    private java.lang.String documentno;

    private java.lang.String message;

    public OrderResponse() {
    }

    public OrderResponse(
           java.lang.String COrderId,
           java.lang.String docstatus,
           java.lang.String documentno,
           java.lang.String message) {
           this.COrderId = COrderId;
           this.docstatus = docstatus;
           this.documentno = documentno;
           this.message = message;
    }


    /**
     * Gets the COrderId value for this OrderResponse.
     * 
     * @return COrderId
     */
    public java.lang.String getCOrderId() {
        return COrderId;
    }


    /**
     * Sets the COrderId value for this OrderResponse.
     * 
     * @param COrderId
     */
    public void setCOrderId(java.lang.String COrderId) {
        this.COrderId = COrderId;
    }


    /**
     * Gets the docstatus value for this OrderResponse.
     * 
     * @return docstatus
     */
    public java.lang.String getDocstatus() {
        return docstatus;
    }


    /**
     * Sets the docstatus value for this OrderResponse.
     * 
     * @param docstatus
     */
    public void setDocstatus(java.lang.String docstatus) {
        this.docstatus = docstatus;
    }


    /**
     * Gets the documentno value for this OrderResponse.
     * 
     * @return documentno
     */
    public java.lang.String getDocumentno() {
        return documentno;
    }


    /**
     * Sets the documentno value for this OrderResponse.
     * 
     * @param documentno
     */
    public void setDocumentno(java.lang.String documentno) {
        this.documentno = documentno;
    }


    /**
     * Gets the message value for this OrderResponse.
     * 
     * @return message
     */
    public java.lang.String getMessage() {
        return message;
    }


    /**
     * Sets the message value for this OrderResponse.
     * 
     * @param message
     */
    public void setMessage(java.lang.String message) {
        this.message = message;
    }

    private java.lang.Object __equalsCalc = null;
    public synchronized boolean equals(java.lang.Object obj) {
        if (!(obj instanceof OrderResponse)) return false;
        OrderResponse other = (OrderResponse) obj;
        if (obj == null) return false;
        if (this == obj) return true;
        if (__equalsCalc != null) {
            return (__equalsCalc == obj);
        }
        __equalsCalc = obj;
        boolean _equals;
        _equals = true && 
            ((this.COrderId==null && other.getCOrderId()==null) || 
             (this.COrderId!=null &&
              this.COrderId.equals(other.getCOrderId()))) &&
            ((this.docstatus==null && other.getDocstatus()==null) || 
             (this.docstatus!=null &&
              this.docstatus.equals(other.getDocstatus()))) &&
            ((this.documentno==null && other.getDocumentno()==null) || 
             (this.documentno!=null &&
              this.documentno.equals(other.getDocumentno()))) &&
            ((this.message==null && other.getMessage()==null) || 
             (this.message!=null &&
              this.message.equals(other.getMessage())));
        __equalsCalc = null;
        return _equals;
    }

    private boolean __hashCodeCalc = false;
    public synchronized int hashCode() {
        if (__hashCodeCalc) {
            return 0;
        }
        __hashCodeCalc = true;
        int _hashCode = 1;
        if (getCOrderId() != null) {
            _hashCode += getCOrderId().hashCode();
        }
        if (getDocstatus() != null) {
            _hashCode += getDocstatus().hashCode();
        }
        if (getDocumentno() != null) {
            _hashCode += getDocumentno().hashCode();
        }
        if (getMessage() != null) {
            _hashCode += getMessage().hashCode();
        }
        __hashCodeCalc = false;
        return _hashCode;
    }

    // Type metadata
    private static org.apache.axis.description.TypeDesc typeDesc =
        new org.apache.axis.description.TypeDesc(OrderResponse.class, true);

    static {
        typeDesc.setXmlType(new javax.xml.namespace.QName("/services/WebService", "OrderResponse"));
        org.apache.axis.description.ElementDesc elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("COrderId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "COrderId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("docstatus");
        elemField.setXmlName(new javax.xml.namespace.QName("", "docstatus"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("documentno");
        elemField.setXmlName(new javax.xml.namespace.QName("", "documentno"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("message");
        elemField.setXmlName(new javax.xml.namespace.QName("", "message"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
    }

    /**
     * Return type metadata object
     */
    public static org.apache.axis.description.TypeDesc getTypeDesc() {
        return typeDesc;
    }

    /**
     * Get Custom Serializer
     */
    public static org.apache.axis.encoding.Serializer getSerializer(
           java.lang.String mechType, 
           java.lang.Class _javaType,  
           javax.xml.namespace.QName _xmlType) {
        return 
          new  org.apache.axis.encoding.ser.BeanSerializer(
            _javaType, _xmlType, typeDesc);
    }

    /**
     * Get Custom Deserializer
     */
    public static org.apache.axis.encoding.Deserializer getDeserializer(
           java.lang.String mechType, 
           java.lang.Class _javaType,  
           javax.xml.namespace.QName _xmlType) {
        return 
          new  org.apache.axis.encoding.ser.BeanDeserializer(
            _javaType, _xmlType, typeDesc);
    }

}
