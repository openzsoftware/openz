package org.zsoft.ecommerce.order.client.sangro.response;

import javax.xml.bind.annotation.XmlElement;

public class Bestellungen {
  private Bestellung[] Bestellung;

  private ABL[] ABL;
  @XmlElement(name = "Bestellung")
  public Bestellung[] getBestellung ()
  {
      return Bestellung;
  }

  public void setBestellung (Bestellung[] Bestellung)
  {
      this.Bestellung = Bestellung;
  }

  public ABL[] getABL ()
  {
      return ABL;
  }

  public void setABL (ABL[] ABL)
  {
      this.ABL = ABL;
  }

}
