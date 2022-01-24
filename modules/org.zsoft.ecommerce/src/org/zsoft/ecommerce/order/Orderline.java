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
package org.zsoft.ecommerce.order;
import java.util.Date;
import java.math.BigDecimal;
import org.zsoft.ecommerce.*;

public class Orderline {

  private String  cOrderlineId;
  
  public String getCOrderlineId() {
       return cOrderlineId;
  }
 
  public void setCOrderlineId(String pcOrderlineId) {
       cOrderlineId = pcOrderlineId;
  }
 
    private String  cOrderId;
 
  public String getCOrderId() {
       return cOrderId;
  }
 
  public void setCOrderId(String pcOrderId) {
       cOrderId = pcOrderId;
  }
 
    private BigDecimal  line;
 
  public BigDecimal getLine() {
       return line;
  }
 
  public void setLine(BigDecimal pline) {
       line = pline;
  }
 
    private Date  datepromised;
 
  public Date getDatepromised() {
       return datepromised;
  }
 
  public void setDatepromised(Date pdatepromised) {
       datepromised = pdatepromised;
  }
 
    private Date  datedelivered;
 
  public Date getDatedelivered() {
       return datedelivered;
  }
 
  public void setDatedelivered(Date pdatedelivered) {
       datedelivered = pdatedelivered;
  }
 
    private Date  dateinvoiced;
 
  public Date getDateinvoiced() {
       return dateinvoiced;
  }
 
  public void setDateinvoiced(Date pdateinvoiced) {
       dateinvoiced = pdateinvoiced;
  }
  private String  description;
  
  public String getDescription() {
       return description;
  }
 
  public void setDescription(String pdescription) {
       description = pdescription;
  }
 
    private String  mProductId;
 
  public String getMProductId() {
       return mProductId;
  }
 
  public void setMProductId(String pmProductId) {
       mProductId = pmProductId;
  }
 
    private BigDecimal  qtyordered;
 
  public BigDecimal getQtyordered() {
       return qtyordered;
  }
 
  public void setQtyordered(BigDecimal pqtyordered) {
       qtyordered = pqtyordered;
  }
 
    private BigDecimal  qtydelivered;
 
  public BigDecimal getQtydelivered() {
       return qtydelivered;
  }
 
  public void setQtydelivered(BigDecimal pqtydelivered) {
       qtydelivered = pqtydelivered;
  }
 
    private BigDecimal  qtyinvoiced;
 
  public BigDecimal getQtyinvoiced() {
       return qtyinvoiced;
  }
 
  public void setQtyinvoiced(BigDecimal pqtyinvoiced) {
       qtyinvoiced = pqtyinvoiced;
  }
 
    private BigDecimal  priceactual;
 
  public BigDecimal getPriceactual() {
    return priceactual;
  }
 
  public void setPriceactual(BigDecimal ppriceactual) {
       priceactual = ppriceactual;
  }
 
}
