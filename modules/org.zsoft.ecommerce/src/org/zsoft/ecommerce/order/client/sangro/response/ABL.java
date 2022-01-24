package org.zsoft.ecommerce.order.client.sangro.response;

import javax.xml.bind.annotation.XmlElement;

public class ABL {
  private String BelegNummer;

  private String Bestellreferenz;

  private String Zustelldatum;

  private Spedition Spedtion;

  private Image image;
  @XmlElement(name = "BelegNummer")
  public String getBelegNummer ()
  {
      return BelegNummer;
  }

  public void setBelegNummer (String BelegNummer)
  {
      this.BelegNummer = BelegNummer;
  }
  @XmlElement(name = "Bestellreferenz")
  public String getBestellreferenz ()
  {
      return Bestellreferenz;
  }

  public void setBestellreferenz (String Bestellreferenz)
  {
      this.Bestellreferenz = Bestellreferenz;
  }
  @XmlElement(name = "Zustelldatum")
  public String getZustelldatum ()
  {
      return Zustelldatum;
  }

  public void setZustelldatum (String Zustelldatum)
  {
      this.Zustelldatum = Zustelldatum;
  }
  @XmlElement(name = "Spedtion")
  public Spedition getSpedtion ()
  {
      return Spedtion;
  }

  public void setSpedtion (Spedition Spedtion)
  {
      this.Spedtion = Spedtion;
  }

  public Image getImage ()
  {
      return image;
  }

  public void setImage (Image image)
  {
      this.image = image;
  }
}
