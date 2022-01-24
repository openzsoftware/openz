package org.zsoft.ecommerce.order.client.sangro.request;

import javax.xml.bind.annotation.XmlElement;

public class Zuzahlungsrechnung {
  private String Belegnummer;
  @XmlElement(name = "Belegnummer")
  public String getBelegnummer ()
  {
      return Belegnummer;
  }

  public void setBelegnummer (String Belegnummer)
  {
      this.Belegnummer = Belegnummer;
  }

  @Override
  public String toString()
  {
      return "ClassPojo [Belegnummer = "+Belegnummer+"]";
  }
}
