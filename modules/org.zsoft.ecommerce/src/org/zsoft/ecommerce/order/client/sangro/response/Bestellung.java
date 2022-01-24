package org.zsoft.ecommerce.order.client.sangro.response;

import javax.xml.bind.annotation.XmlElement;

public class Bestellung {
  private Spedition Spedition;

  private String BelegNummer;

  private String Bestellreferenz;

  private String LieferDatum;

  private Positionen Positionen;
  @XmlElement(name = "Spedition")
  public Spedition getSpedition ()
  {
      return Spedition;
  }

  public void setSpedition (Spedition Spedition)
  {
      this.Spedition = Spedition;
  }
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
  @XmlElement(name = "LieferDatum")
  public String getLieferDatum ()
  {
      return LieferDatum;
  }

  public void setLieferDatum (String LieferDatum)
  {
      this.LieferDatum = LieferDatum;
  }
  @XmlElement(name = "Positionen")
  public Positionen getPositionen ()
  {
      return Positionen;
  }

  public void setPositionen (Positionen Positionen)
  {
      this.Positionen = Positionen;
  }

}
