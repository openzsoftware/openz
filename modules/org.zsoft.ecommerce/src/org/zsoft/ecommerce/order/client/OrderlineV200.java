/**
 * Orderline.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.zsoft.ecommerce.order.client;



public class OrderlineV200  implements java.io.Serializable {
    private java.lang.String COrderId;

    private java.lang.String COrderlineId;

    private java.lang.String MAttributesetinstanceId;

    private java.lang.String MProductId;

    private java.util.Date datedelivered;

    private java.util.Date dateinvoiced;

    private java.util.Date datepromised;

    private java.lang.String description;

    private java.math.BigDecimal line;

    private java.math.BigDecimal priceactual;

    private java.math.BigDecimal qtydelivered;

    private java.math.BigDecimal qtyinvoiced;

    private java.math.BigDecimal qtyordered;

    public OrderlineV200() {
    }

    public OrderlineV200(
           java.lang.String COrderId,
           java.lang.String COrderlineId,
           java.lang.String MAttributesetinstanceId,
           java.lang.String MProductId,
           java.util.Date datedelivered,
           java.util.Date dateinvoiced,
           java.util.Date datepromised,
           java.lang.String description,
           java.math.BigDecimal line,
           java.math.BigDecimal priceactual,
           java.math.BigDecimal qtydelivered,
           java.math.BigDecimal qtyinvoiced,
           java.math.BigDecimal qtyordered) {
           this.COrderId = COrderId;
           this.COrderlineId = COrderlineId;
           this.MAttributesetinstanceId = MAttributesetinstanceId;
           this.MProductId = MProductId;
           this.datedelivered = datedelivered;
           this.dateinvoiced = dateinvoiced;
           this.datepromised = datepromised;
           this.description = description;
           this.line = line;
           this.priceactual = priceactual;
           this.qtydelivered = qtydelivered;
           this.qtyinvoiced = qtyinvoiced;
           this.qtyordered = qtyordered;
    }


    /**
     * Gets the COrderId value for this OrderlineV200.
     * 
     * @return COrderId
     */
    public java.lang.String getCOrderId() {
        return COrderId;
    }


    /**
     * Sets the COrderId value for this OrderlineV200.
     * 
     * @param COrderId
     */
    public void setCOrderId(java.lang.String COrderId) {
        this.COrderId = COrderId;
    }


    /**
     * Gets the COrderlineId value for this OrderlineV200.
     * 
     * @return COrderlineId
     */
    public java.lang.String getCOrderlineId() {
        return COrderlineId;
    }


    /**
     * Sets the COrderlineId value for this OrderlineV200.
     * 
     * @param COrderlineId
     */
    public void setCOrderlineId(java.lang.String COrderlineId) {
        this.COrderlineId = COrderlineId;
    }


    /**
     * Gets the MAttributesetinstanceId value for this OrderlineV200.
     * 
     * @return MAttributesetinstanceId
     */
    public java.lang.String getMAttributesetinstanceId() {
        return MAttributesetinstanceId;
    }


    /**
     * Sets the MAttributesetinstanceId value for this OrderlineV200.
     * 
     * @param MAttributesetinstanceId
     */
    public void setMAttributesetinstanceId(java.lang.String MAttributesetinstanceId) {
        this.MAttributesetinstanceId = MAttributesetinstanceId;
    }


    /**
     * Gets the MProductId value for this OrderlineV200.
     * 
     * @return MProductId
     */
    public java.lang.String getMProductId() {
        return MProductId;
    }


    /**
     * Sets the MProductId value for this OrderlineV200.
     * 
     * @param MProductId
     */
    public void setMProductId(java.lang.String MProductId) {
        this.MProductId = MProductId;
    }


    /**
     * Gets the datedelivered value for this OrderlineV200.
     * 
     * @return datedelivered
     */
    public java.util.Date getDatedelivered() {
        return datedelivered;
    }


    /**
     * Sets the datedelivered value for this OrderlineV200.
     * 
     * @param datedelivered
     */
    public void setDatedelivered(java.util.Date datedelivered) {
        this.datedelivered = datedelivered;
    }


    /**
     * Gets the dateinvoiced value for this OrderlineV200.
     * 
     * @return dateinvoiced
     */
    public java.util.Date getDateinvoiced() {
        return dateinvoiced;
    }


    /**
     * Sets the dateinvoiced value for this OrderlineV200.
     * 
     * @param dateinvoiced
     */
    public void setDateinvoiced(java.util.Date dateinvoiced) {
        this.dateinvoiced = dateinvoiced;
    }


    /**
     * Gets the datepromised value for this OrderlineV200.
     * 
     * @return datepromised
     */
    public java.util.Date getDatepromised() {
        return datepromised;
    }


    /**
     * Sets the datepromised value for this OrderlineV200.
     * 
     * @param datepromised
     */
    public void setDatepromised(java.util.Date datepromised) {
        this.datepromised = datepromised;
    }


    /**
     * Gets the description value for this OrderlineV200.
     * 
     * @return description
     */
    public java.lang.String getDescription() {
        return description;
    }


    /**
     * Sets the description value for this OrderlineV200.
     * 
     * @param description
     */
    public void setDescription(java.lang.String description) {
        this.description = description;
    }


    /**
     * Gets the line value for this OrderlineV200.
     * 
     * @return line
     */
    public java.math.BigDecimal getLine() {
        return line;
    }


    /**
     * Sets the line value for this OrderlineV200.
     * 
     * @param line
     */
    public void setLine(java.math.BigDecimal line) {
        this.line = line;
    }


    /**
     * Gets the priceactual value for this OrderlineV200.
     * 
     * @return priceactual
     */
    public java.math.BigDecimal getPriceactual() {
        return priceactual;
    }


    /**
     * Sets the priceactual value for this OrderlineV200.
     * 
     * @param priceactual
     */
    public void setPriceactual(java.math.BigDecimal priceactual) {
        this.priceactual = priceactual;
    }


    /**
     * Gets the qtydelivered value for this OrderlineV200.
     * 
     * @return qtydelivered
     */
    public java.math.BigDecimal getQtydelivered() {
        return qtydelivered;
    }


    /**
     * Sets the qtydelivered value for this OrderlineV200.
     * 
     * @param qtydelivered
     */
    public void setQtydelivered(java.math.BigDecimal qtydelivered) {
        this.qtydelivered = qtydelivered;
    }


    /**
     * Gets the qtyinvoiced value for this OrderlineV200.
     * 
     * @return qtyinvoiced
     */
    public java.math.BigDecimal getQtyinvoiced() {
        return qtyinvoiced;
    }


    /**
     * Sets the qtyinvoiced value for this OrderlineV200.
     * 
     * @param qtyinvoiced
     */
    public void setQtyinvoiced(java.math.BigDecimal qtyinvoiced) {
        this.qtyinvoiced = qtyinvoiced;
    }


    /**
     * Gets the qtyordered value for this OrderlineV200.
     * 
     * @return qtyordered
     */
    public java.math.BigDecimal getQtyordered() {
        return qtyordered;
    }


    /**
     * Sets the qtyordered value for this OrderlineV200.
     * 
     * @param qtyordered
     */
    public void setQtyordered(java.math.BigDecimal qtyordered) {
        this.qtyordered = qtyordered;
    }

    private java.lang.Object __equalsCalc = null;
    public synchronized boolean equals(java.lang.Object obj) {
        if (!(obj instanceof OrderlineV200)) return false;
        OrderlineV200 other = (OrderlineV200) obj;
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
            ((this.COrderlineId==null && other.getCOrderlineId()==null) || 
             (this.COrderlineId!=null &&
              this.COrderlineId.equals(other.getCOrderlineId()))) &&
            ((this.MAttributesetinstanceId==null && other.getMAttributesetinstanceId()==null) || 
             (this.MAttributesetinstanceId!=null &&
              this.MAttributesetinstanceId.equals(other.getMAttributesetinstanceId()))) &&
            ((this.MProductId==null && other.getMProductId()==null) || 
             (this.MProductId!=null &&
              this.MProductId.equals(other.getMProductId()))) &&
            ((this.datedelivered==null && other.getDatedelivered()==null) || 
             (this.datedelivered!=null &&
              this.datedelivered.equals(other.getDatedelivered()))) &&
            ((this.dateinvoiced==null && other.getDateinvoiced()==null) || 
             (this.dateinvoiced!=null &&
              this.dateinvoiced.equals(other.getDateinvoiced()))) &&
            ((this.datepromised==null && other.getDatepromised()==null) || 
             (this.datepromised!=null &&
              this.datepromised.equals(other.getDatepromised()))) &&
            ((this.description==null && other.getDescription()==null) || 
             (this.description!=null &&
              this.description.equals(other.getDescription()))) &&
            ((this.line==null && other.getLine()==null) || 
             (this.line!=null &&
              this.line.equals(other.getLine()))) &&
            ((this.priceactual==null && other.getPriceactual()==null) || 
             (this.priceactual!=null &&
              this.priceactual.equals(other.getPriceactual()))) &&
            ((this.qtydelivered==null && other.getQtydelivered()==null) || 
             (this.qtydelivered!=null &&
              this.qtydelivered.equals(other.getQtydelivered()))) &&
            ((this.qtyinvoiced==null && other.getQtyinvoiced()==null) || 
             (this.qtyinvoiced!=null &&
              this.qtyinvoiced.equals(other.getQtyinvoiced()))) &&
            ((this.qtyordered==null && other.getQtyordered()==null) || 
             (this.qtyordered!=null &&
              this.qtyordered.equals(other.getQtyordered())));
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
        if (getCOrderlineId() != null) {
            _hashCode += getCOrderlineId().hashCode();
        }
        if (getMAttributesetinstanceId() != null) {
            _hashCode += getMAttributesetinstanceId().hashCode();
        }
        if (getMProductId() != null) {
            _hashCode += getMProductId().hashCode();
        }
        if (getDatedelivered() != null) {
            _hashCode += getDatedelivered().hashCode();
        }
        if (getDateinvoiced() != null) {
            _hashCode += getDateinvoiced().hashCode();
        }
        if (getDatepromised() != null) {
            _hashCode += getDatepromised().hashCode();
        }
        if (getDescription() != null) {
            _hashCode += getDescription().hashCode();
        }
        if (getLine() != null) {
            _hashCode += getLine().hashCode();
        }
        if (getPriceactual() != null) {
            _hashCode += getPriceactual().hashCode();
        }
        if (getQtydelivered() != null) {
            _hashCode += getQtydelivered().hashCode();
        }
        if (getQtyinvoiced() != null) {
            _hashCode += getQtyinvoiced().hashCode();
        }
        if (getQtyordered() != null) {
            _hashCode += getQtyordered().hashCode();
        }
        __hashCodeCalc = false;
        return _hashCode;
    }

    // Type metadata
    private static org.apache.axis.description.TypeDesc typeDesc =
        new org.apache.axis.description.TypeDesc(OrderlineV200.class, true);

    static {
        typeDesc.setXmlType(new javax.xml.namespace.QName("/services/WebService", "OrderlineV200"));
        org.apache.axis.description.ElementDesc elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("COrderId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "COrderId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("COrderlineId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "COrderlineId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("MAttributesetinstanceId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "MAttributesetinstanceId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("MProductId");
        elemField.setXmlName(new javax.xml.namespace.QName("", "MProductId"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("datedelivered");
        elemField.setXmlName(new javax.xml.namespace.QName("", "datedelivered"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "dateTime"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("dateinvoiced");
        elemField.setXmlName(new javax.xml.namespace.QName("", "dateinvoiced"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "dateTime"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("datepromised");
        elemField.setXmlName(new javax.xml.namespace.QName("", "datepromised"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "dateTime"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("description");
        elemField.setXmlName(new javax.xml.namespace.QName("", "description"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "string"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("line");
        elemField.setXmlName(new javax.xml.namespace.QName("", "line"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "decimal"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("priceactual");
        elemField.setXmlName(new javax.xml.namespace.QName("", "priceactual"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "decimal"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("qtydelivered");
        elemField.setXmlName(new javax.xml.namespace.QName("", "qtydelivered"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "decimal"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("qtyinvoiced");
        elemField.setXmlName(new javax.xml.namespace.QName("", "qtyinvoiced"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "decimal"));
        elemField.setNillable(true);
        typeDesc.addFieldDesc(elemField);
        elemField = new org.apache.axis.description.ElementDesc();
        elemField.setFieldName("qtyordered");
        elemField.setXmlName(new javax.xml.namespace.QName("", "qtyordered"));
        elemField.setXmlType(new javax.xml.namespace.QName("http://www.w3.org/2001/XMLSchema", "decimal"));
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
