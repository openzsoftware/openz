package org.zsoft.ecommerce.product.client.emporium.response;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "Stock")
public class StockEntry
{
  private Stock Stock;
  @XmlElement(name = "stock")
  public Stock getStock ()
  {
      return Stock;
  }

  public void setStock (Stock Stock)
  {
      this.Stock = Stock;
  }

  @Override
  public String toString()
  {
      return "ClassPojo [Stock = "+Stock+"]";
  }
}