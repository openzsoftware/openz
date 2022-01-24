package org.zsoft.ecommerce.product;

import java.util.Date;
import java.math.BigDecimal;

public class Quanities {
  private Date  nextdeliverydate;
  
  public Date getNextdeliverydate() {
       return nextdeliverydate;
  }
 
  public void setNextdeliverydate(Date pnextdeliverydate) {
    nextdeliverydate = pnextdeliverydate;
  }
   private BigDecimal  nextdeliveryqty;
  
  public BigDecimal getNextdeliveryqty() {
       return nextdeliveryqty;
  }
 
  public void setNextdeliveryqty(BigDecimal pnextdeliveryqty) {
    nextdeliveryqty = pnextdeliveryqty;
  }
  private BigDecimal  currentonhandqty;
  
  public BigDecimal getCurrentonhandqty() {
       return currentonhandqty;
  }
 
  public void setCurrentonhandqty(BigDecimal pcurrentonhandqty) {
    currentonhandqty = pcurrentonhandqty;
  }
  
}
