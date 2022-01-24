package org.zsoft.ecommerce.order.client.sangro.request;

import javax.xml.bind.annotation.XmlElement;

public class Bestellung {
  private String LauerlisteLieferantId;

  private String Bemerkung;

  private String DirektLieferung;

  private String GLN;

  private String BelegNummer;

  private Zuzahlungsrechnung Zuzahlungsrechnung;

  private String KundennummerBeimLieferanten;

  private String LieferDatum;
  
  private String VersandArt;

  private Positionen Positionen;

  private String LieferTerminWunsch;

  private String GS1Basisnummer;

  private Kommission Kommission;

  public String getLauerlisteLieferantId ()
  {
      return LauerlisteLieferantId;
  }

  public void setLauerlisteLieferantId (String LauerlisteLieferantId)
  {
      this.LauerlisteLieferantId = LauerlisteLieferantId;
  }
 
  public void setVersandArt (String VersandArt)
  {
      this.VersandArt = VersandArt;
  }
  public String getVersandArt ()
  {
      return VersandArt;
  }
  @XmlElement(name = "Bemerkung")
  public String getBemerkung ()
  {
      return Bemerkung;
  }

  public void setBemerkung (String Bemerkung)
  {
      this.Bemerkung = Bemerkung;
  }
  @XmlElement(name = "DirektLieferung")
  public String getDirektLieferung ()
  {
      return DirektLieferung;
  }

  public void setDirektLieferung (String DirektLieferung)
  {
      this.DirektLieferung = DirektLieferung;
  }

  public String getGLN ()
  {
      return GLN;
  }

  public void setGLN (String GLN)
  {
      this.GLN = GLN;
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
  @XmlElement(name = "Zuzahlungsrechnung")
  public Zuzahlungsrechnung getZuzahlungsrechnung ()
  {
      return Zuzahlungsrechnung;
  }

  public void setZuzahlungsrechnung (Zuzahlungsrechnung Zuzahlungsrechnung)
  {
      this.Zuzahlungsrechnung = Zuzahlungsrechnung;
  }
  @XmlElement(name = "KundennummerBeimLieferanten")
  public String getKundennummerBeimLieferanten ()
  {
      return KundennummerBeimLieferanten;
  }

  public void setKundennummerBeimLieferanten (String KundennummerBeimLieferanten)
  {
      this.KundennummerBeimLieferanten = KundennummerBeimLieferanten;
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
  @XmlElement(name = "LieferTerminWunsch")
  public String getLieferTerminWunsch ()
  {
      return LieferTerminWunsch;
  }

  public void setLieferTerminWunsch (String LieferTerminWunsch)
  {
      this.LieferTerminWunsch = LieferTerminWunsch;
  }
  @XmlElement(name = "GS1Basisnummer")
  public String getGS1Basisnummer ()
  {
      return GS1Basisnummer;
  }

  public void setGS1Basisnummer (String GS1Basisnummer)
  {
      this.GS1Basisnummer = GS1Basisnummer;
  }
  @XmlElement(name = "Kommission")
  public Kommission getKommission ()
  {
      return Kommission;
  }

  public void setKommission (Kommission Kommission)
  {
      this.Kommission = Kommission;
  }

  @Override
  public String toString()
  {
      return "ClassPojo [LauerlisteLieferantId = "+LauerlisteLieferantId+", Bemerkung = "+Bemerkung+", DirektLieferung = "+DirektLieferung+", GLN = "+GLN+", BelegNummer = "+BelegNummer+", Zuzahlungsrechnung = "+Zuzahlungsrechnung+", KundennummerBeimLieferanten = "+KundennummerBeimLieferanten+", LieferDatum = "+LieferDatum+", Positionen = "+Positionen+", LieferTerminWunsch = "+LieferTerminWunsch+", GS1Basisnummer = "+GS1Basisnummer+", Kommission = "+Kommission+"]";
  }
}
