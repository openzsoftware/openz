package org.zsoft.ecommerce.order.client.sangro.request;

import javax.xml.bind.annotation.XmlElement;

public class Kommission {
  private String Nachname;

  private String Name3;
  
  private String Land;

  private String Ort;

  private String Strasse;

  private String KundenNummer;

  private String PLZ;

  private String Vorname;
  @XmlElement(name = "Nachname")
  public String getNachname ()
  {
      return Nachname;
  }

  public void setNachname (String Nachname)
  {
      this.Nachname = Nachname;
  }
  @XmlElement(name = "Name3")
  public String getName3 ()
  {
      return Name3;
  }

  public void setLand (String Land)
  {
      this.Land = Land;
  }
  public String getLand ()
  {
      return Land;
  }

  public void setName3 (String Name3)
  {
      this.Name3 = Name3;
  }
  @XmlElement(name = "Ort")
  public String getOrt ()
  {
      return Ort;
  }

  public void setOrt (String Ort)
  {
      this.Ort = Ort;
  }
  @XmlElement(name = "Strasse")
  public String getStrasse ()
  {
      return Strasse;
  }

  public void setStrasse (String Strasse)
  {
      this.Strasse = Strasse;
  }
  @XmlElement(name = "KundenNummer")
  public String getKundenNummer ()
  {
      return KundenNummer;
  }

  public void setKundenNummer (String KundenNummer)
  {
      this.KundenNummer = KundenNummer;
  }

  public String getPLZ ()
  {
      return PLZ;
  }

  public void setPLZ (String PLZ)
  {
      this.PLZ = PLZ;
  }
  @XmlElement(name = "Vorname")
  public String getVorname ()
  {
      return Vorname;
  }

  public void setVorname (String Vorname)
  {
      this.Vorname = Vorname;
  }

  @Override
  public String toString()
  {
      return "ClassPojo [Nachname = "+Nachname+", Name3 = "+Name3+", Ort = "+Ort+", Strasse = "+Strasse+", KundenNummer = "+KundenNummer+", PLZ = "+PLZ+", Vorname = "+Vorname+"]";
  }
}
