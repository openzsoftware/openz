package org.zsoft.ecommerce.order.client.sangro.response;

import javax.xml.bind.annotation.XmlElement;

public class Spedition {
  private String Name;

  private String Referenznummer;
  @XmlElement(name = "Name")
  public String getName ()
  {
      return Name;
  }

  public void setName (String Name)
  {
      this.Name = Name;
  }
  @XmlElement(name = "Referenznummer")
  public String getReferenznummer ()
  {
      return Referenznummer;
  }

  public void setReferenznummer (String Referenznummer)
  {
      this.Referenznummer = Referenznummer;
  }

}
