package org.zsoft.ecommerce.order.client.sangro.request;

import javax.xml.bind.annotation.XmlElement;

public class Position {
  private String PZN;

  private String ErsatzArtikel;

  private String PositionsNummer;

  private String EAN;

  private String Menge;

  private String VerordnungszeitraumBis;

  private String EinzelpreisRabattiert;

  private String Artikelnummer;

  private String Liefertermine;

  private String Herstellerartikelnummer;

  private String Mengeneinheit;

  private String Bezeichnung;

  private String VerordnungszeitraumVon;

  private String Preiseinheiten;

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

  public String getEAN ()
  {
      return EAN;
  }

  public void setEAN (String EAN)
  {
      this.EAN = EAN;
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
  @XmlElement(name = "VerordnungszeitraumBis")
  public String getVerordnungszeitraumBis ()
  {
      return VerordnungszeitraumBis;
  }

  public void setVerordnungszeitraumBis (String VerordnungszeitraumBis)
  {
      this.VerordnungszeitraumBis = VerordnungszeitraumBis;
  }
  @XmlElement(name = "EinzelpreisRabattiert")
  public String getEinzelpreisRabattiert ()
  {
      return EinzelpreisRabattiert;
  }

  public void setEinzelpreisRabattiert (String EinzelpreisRabattiert)
  {
      this.EinzelpreisRabattiert = EinzelpreisRabattiert;
  }
  @XmlElement(name = "Artikelnummer")
  public String getArtikelnummer ()
  {
      return Artikelnummer;
  }

  public void setArtikelnummer (String Artikelnummer)
  {
      this.Artikelnummer = Artikelnummer;
  }
  @XmlElement(name = "Liefertermine")
  public String getLiefertermine ()
  {
      return Liefertermine;
  }

  public void setLiefertermine (String Liefertermine)
  {
      this.Liefertermine = Liefertermine;
  }
  @XmlElement(name = "Herstellerartikelnummer")
  public String getHerstellerartikelnummer ()
  {
      return Herstellerartikelnummer;
  }

  public void setHerstellerartikelnummer (String Herstellerartikelnummer)
  {
      this.Herstellerartikelnummer = Herstellerartikelnummer;
  }
  @XmlElement(name = "Mengeneinheit")
  public String getMengeneinheit ()
  {
      return Mengeneinheit;
  }

  public void setMengeneinheit (String Mengeneinheit)
  {
      this.Mengeneinheit = Mengeneinheit;
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
  @XmlElement(name = "VerordnungszeitraumVon")
  public String getVerordnungszeitraumVon ()
  {
      return VerordnungszeitraumVon;
  }

  public void setVerordnungszeitraumVon (String VerordnungszeitraumVon)
  {
      this.VerordnungszeitraumVon = VerordnungszeitraumVon;
  }
  @XmlElement(name = "Preiseinheiten")
  public String getPreiseinheiten ()
  {
      return Preiseinheiten;
  }

  public void setPreiseinheiten (String Preiseinheiten)
  {
      this.Preiseinheiten = Preiseinheiten;
  }

  @Override
  public String toString()
  {
      return "ClassPojo [PZN = "+PZN+", ErsatzArtikel = "+ErsatzArtikel+", PositionsNummer = "+PositionsNummer+", EAN = "+EAN+", Menge = "+Menge+", VerordnungszeitraumBis = "+VerordnungszeitraumBis+", EinzelpreisRabattiert = "+EinzelpreisRabattiert+", Artikelnummer = "+Artikelnummer+", Liefertermine = "+Liefertermine+", Herstellerartikelnummer = "+Herstellerartikelnummer+", Mengeneinheit = "+Mengeneinheit+", Bezeichnung = "+Bezeichnung+", VerordnungszeitraumVon = "+VerordnungszeitraumVon+", Preiseinheiten = "+Preiseinheiten+"]";
  }
}
