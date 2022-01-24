/**
 * OrderV100.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.zsoft.ecommerce.order.client;



public class OrderV200  implements java.io.Serializable {
    private java.lang.String CBpartnerContactId;

    private java.lang.String CBpartnerId;

    private java.lang.String CBpartnerLocationId;

    private java.lang.String COrderId;

    private java.lang.String deliveryviarule;

    private java.lang.String docstatus;

    private java.lang.String documentno;

    private java.lang.String isdelivered;

    private java.lang.String isinvoiced;

    private OrderlineV200[] orderlines;

    private java.lang.String paymentrule;

    public OrderV200() {
    }

    public OrderV200(
           java.lang.String CBpartnerContactId,
           java.lang.String CBpartnerId,
           java.lang.String CBpartnerLocationId,
           java.lang.String COrderId,
           java.lang.String deliveryviarule,
           java.lang.String docstatus,
           java.lang.String documentno,
           java.lang.String isdelivered,
           java.lang.String isinvoiced,
           OrderlineV200[] orderlines,
           java.lang.String paymentrule) {
           this.CBpartnerContactId = CBpartnerContactId;
           this.CBpartnerId = CBpartnerId;
           this.CBpartnerLocationId = CBpartnerLocationId;
           this.COrderId = COrderId;
           this.deliveryviarule = deliveryviarule;
           this.docstatus = docstatus;
           this.documentno = documentno;
           this.isdelivered = isdelivered;
           this.isinvoiced = isinvoiced;
           this.orderlines = orderlines;
           this.paymentrule = paymentrule;
    }


    /**
     * Gets the CBpartnerContactId value for this OrderV200.
     * 
     * @return CBpartnerContactId
     */
    public java.lang.String getCBpartnerContactId() {
        return CBpartnerContactId;
    }


    /**
     * Sets the CBpartnerContactId value for this OrderV200.
     * 
     * @param CBpartnerContactId
     */
    public void setCBpartnerContactId(java.lang.String CBpartnerContactId) {
        this.CBpartnerContactId = CBpartnerContactId;
    }


    /**
     * Gets the CBpartnerId value for this OrderV200.
     * 
     * @return CBpartnerId
     */
    public java.lang.String getCBpartnerId() {
        return CBpartnerId;
    }


    /**
     * Sets the CBpartnerId value for this OrderV200.
     * 
     * @param CBpartnerId
     */
    public void setCBpartnerId(java.lang.String CBpartnerId) {
        this.CBpartnerId = CBpartnerId;
    }


    /**
     * Gets the CBpartnerLocationId value for this OrderV200.
     * 
     * @return CBpartnerLocationId
     */
    public java.lang.String getCBpartnerLocationId() {
        return CBpartnerLocationId;
    }


    /**
     * Sets the CBpartnerLocationId value for this OrderV200.
     * 
     * @param CBpartnerLocationId
     */
    public void setCBpartnerLocationId(java.lang.String CBpartnerLocationId) {
        this.CBpartnerLocationId = CBpartnerLocationId;
    }


    /**
     * Gets the COrderId value for this OrderV200.
     * 
     * @return COrderId
     */
    public java.lang.String getCOrderId() {
        return COrderId;
    }


    /**
     * Sets the COrderId value for this OrderV200.
     * 
     * @param COrderId
     */
    public void setCOrderId(java.lang.String COrderId) {
        this.COrderId = COrderId;
    }


    /**
     * Gets the deliveryviarule value for this OrderV200.
     * 
     * @return deliveryviarule
     */
    public java.lang.String getDeliveryviarule() {
        return deliveryviarule;
    }


    /**
     * Sets the deliveryviarule value for this OrderV200.
     * 
     * @param deliveryviarule
     */
    public void setDeliveryviarule(java.lang.String deliveryviarule) {
        this.deliveryviarule = deliveryviarule;
    }


    /**
     * Gets the docstatus value for this OrderV200.
     * 
     * @return docstatus
     */
    public java.lang.String getDocstatus() {
        return docstatus;
    }


    /**
     * Sets the docstatus value for this OrderV200.
     * 
     * @param docstatus
     */
    public void setDocstatus(java.lang.String docstatus) {
        this.docstatus = docstatus;
    }


    /**
     * Gets the documentno value for this OrderV200.
     * 
     * @return documentno
     */
    public java.lang.String getDocumentno() {
        return documentno;
    }


    /**
     * Sets the documentno value for this OrderV200.
     * 
     * @param documentno
     */
    public void setDocumentno(java.lang.String documentno) {
        this.documentno = documentno;
    }


    /**
     * Gets the isdelivered value for this OrderV200.
     * 
     * @return isdelivered
     */
    public java.lang.String getIsdelivered() {
        return isdelivered;
    }


    /**
     * Sets the isdelivered value for this OrderV200.
     * 
     * @param isdelivered
     */
    public void setIsdelivered(java.lang.String isdelivered) {
        this.isdelivered = isdelivered;
    }


    /**
     * Gets the isinvoiced value for this OrderV200.
     * 
     * @return isinvoiced
     */
    public java.lang.String getIsinvoiced() {
        return isinvoiced;
    }


    /**
     * Sets the isinvoiced value for this OrderV200.
     * 
     * @param isinvoiced
     */
    public void setIsinvoiced(java.lang.String isinvoiced) {
        this.isinvoiced = isinvoiced;
    }


    /**
     * Gets the orderlines value for this OrderV200.
     * 
     * @return orderlines
     */
    public OrderlineV200[] getOrderlines() {
        return orderlines;
    }


    /**
     * Sets the orderlines value for this OrderV200.
     * 
     * @param orderlines
     */
    public void setOrderlines(OrderlineV200[] orderlines) {
        this.orderlines = orderlines;
    }


    /**
     * Gets the paymentrule value for this OrderV200.
     * 
     * @return paymentrule
     */
    public java.lang.String getPaymentrule() {
        return paymentrule;
    }


    /**
     * Sets the paymentrule value for this OrderV200.
     * 
     * @param paymentrule
     */
    public void setPaymentrule(java.lang.String paymentrule) {
        this.paymentrule = paymentrule;
    }

    private java.lang.Object __equalsCalc = null;
    public synchronized boolean equals(java.lang.Object obj) {
        if (!(obj instanceof OrderV200)) return false;
        OrderV200 other = (OrderV200) obj;
        if (obj == null) return false;
        if (this == obj) return true;
        if (__equalsCalc != null) {
            return (__equalsCalc == obj);
        }
        __equalsCalc = obj;
        boolean _equals;
        _equals = true && 
            ((this.CBpartnerContactId==null && other.getCBpartnerContactId()==null) || 
             (this.CBpartnerContactId!=null &&
              this.CBpartnerContactId.equals(other.getCBpartnerContactId()))) &&
            ((this.CBpartnerId==null && other.getCBpartnerId()==null) || 
             (this.CBpartnerId!=null &&
              this.CBpartnerId.equals(other.getCBpartnerId()))) &&
            ((this.CBpartnerLocationId==null && other.getCBpartnerLocationId()==null) || 
             (this.CBpartnerLocationId!=null &&
              this.CBpartnerLocationId.equals(other.getCBpartnerLocationId()))) &&
            ((this.COrderId==null && other.getCOrderId()==null) || 
             (this.COrderId!=null &&
              this.COrderId.equals(other.getCOrderId()))) &&
            ((this.deliveryviarule==null && other.getDeliveryviarule()==null) || 
             (this.deliveryviarule!=null &&
              this.deliveryviarule.equals(other.getDeliveryviarule()))) &&
            ((this.docstatus==null && other.getDocstatus()==null) || 
             (this.docstatus!=null &&
              this.docstatus.equals(other.getDocstatus()))) &&
            ((this.documentno==null && other.getDocumentno()==null) || 
             (this.documentno!=null &&
              this.documentno.equals(other.getDocumentno()))) &&
            ((this.isdelivered==null && other.getIsdelivered()==null) || 
             (this.isdelivered!=null &&
              this.isdelivered.equals(other.getIsdelivered()))) &&
            ((this.isinvoiced==null && other.getIsinvoiced()==null) || 
             (this.isinvoiced!=null &&
              this.isinvoiced.equals(other.getIsinvoiced()))) &&
            ((this.orderlines==null && other.getOrderlines()==null) || 
             (this.orderlines!=null &&
              java.util.Arrays.equals(this.orderlines, other.getOrderlines()))) &&
            ((this.paymentrule==null && other.getPaymentrule()==null) || 
             (this.paymentrule!=null &&
              this.paymentrule.equals(other.getPaymentrule())));
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
        if (getCBpartnerContactId() != null) {
            _hashCode += getCBpartnerContactId().hashCode();
        }
        if (getCBpartnerId() != null) {
            _hashCode += getCBpartnerId().hashCode();
        }
        if (getCBpartnerLocationId() != null) {
            _hashCode += getCBpartnerLocationId().hashCode();
        }
        if (getCOrderId() != null) {
            _hashCode += getCOrderId().hashCode();
        }
        if (getDeliveryviarule() != null) {
            _hashCode += getDeliveryviarule().hashCode();
        }
        if (getDocstatus() != null) {
            _hashCode += getDocstatus().hashCode();
        }
        if (getDocumentno() != null) {
            _hashCode += getDocumentno().hashCode();
        }
        if (getIsdelivered() != null) {
            _hashCode += getIsdelivered().hashCode();
        }
        if (getIsinvoiced() != null) {
            _hashCode += getIsinvoiced().hashCode();
        }
        if (getOrderlines() != null) {
            for (int i=0;
                 i<java.lang.reflect.Array.getLength(getOrderlines());
                 i++) {
                java.lang.Object obj = java.lang.reflect.Array.get(getOrderlines(), i);
                if (obj != null &&
                    !obj.getClass().isArray()) {
                    _hashCode += obj.hashCode();
                }
            }
        }
        if (getPaymentrule() != null) {
            _hashCode += getPaymentrule().hashCode();
        }
        __hashCodeCalc = false;
        return _hashCode;
    }

    // Type metadata
    private static org.apache.axis.description.TypeDesc typeDesc =
        new org.apache.axis.description.TypeDesc(OrderV200.class, true);

    static {
        typeDesc.setXmlType(new javax.xml.namespace.QName("/services/WebService", "OrderV200"));
        org.apache.axis.description.ElementDesc elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("CBpartnerContactId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "CBpartnerContactId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("CBpartnerId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "CBpartnerId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("CBpartnerLocationId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "CBpartnerLocationId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("COrderId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "COrderId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("deliveryviarule");
        elemField.setXmlName(new javax.xml.namespace.QName("", "deliveryviarule"));
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
        elemField.setFieldName("isdelivered");
        elemField.setXmlName(new javax.xml.namespace.QName("", "isdelivered"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("isinvoiced");
        elemField.setXmlName(new javax.xml.namespace.QName("", "isinvoiced"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("orderlines");
        elemField.setXmlName(new javax.xml.namespace.QName("", "orderlines"));
        elemField.setXmlType(new javax.xml.namespace.QName("/services/WebService", "OrderlineV200"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("paymentrule");
        elemField.setXmlName(new javax.xml.namespace.QName("", "paymentrule"));
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
