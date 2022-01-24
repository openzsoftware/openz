package org.zsoft.ecommerce.order.client.sangro.request;

import javax.xml.bind.annotation.XmlElement;

public class Bestellungen {
  private Bestellung[] Bestellung;
  
  @XmlElement(name = "Bestellung")
  public Bestellung[] getBestellung ()
  {
      return Bestellung;
  }

  public void setBestellung (Bestellung[] Bestellung)
  {
      this.Bestellung = Bestellung;
  }

  @Override
  public String toString()
  {
      return "ClassPojo [Bestellung = "+Bestellung+"]";
  }
}
