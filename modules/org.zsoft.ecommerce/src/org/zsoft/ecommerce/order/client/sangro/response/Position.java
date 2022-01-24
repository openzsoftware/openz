package org.zsoft.ecommerce.order.client.sangro.response;

import javax.xml.bind.annotation.XmlElement;

public class Position {
  private String PZN;

  private String ErsatzArtikel;

  private String PositionsNummer;

  private String Bestellreferenz;

  private String Menge;

  private String Bezeichnung;

  public String getPZN ()
  {
      return PZN;
  }

  public void setPZN (String PZN)
  {
      this.PZN = PZN;
  }
  @XmlElement(name = "ErsatzArtikel")
  public String getErsatzArtikel ()
  {
      return ErsatzArtikel;
  }

  public void setErsatzArtikel (String ErsatzArtikel)
  {
      this.ErsatzArtikel = ErsatzArtikel;
  }
  @XmlElement(name = "PositionsNummer")
  public String getPositionsNummer ()
  {
      return PositionsNummer;
  }

  public void setPositionsNummer (String PositionsNummer)
  {
      this.PositionsNummer = PositionsNummer;
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
  @XmlElement(name = "Menge")
  public String getMenge ()
  {
      return Menge;
  }

  public void setMenge (String Menge)
  {
      this.Menge = Menge;
  }
  @XmlElement(name = "Bezeichnung")
  public String getBezeichnung ()
  {
      return Bezeichnung;
  }

  public void setBezeichnung (String Bezeichnung)
  {
      this.Bezeichnung = Bezeichnung;
  }
}
