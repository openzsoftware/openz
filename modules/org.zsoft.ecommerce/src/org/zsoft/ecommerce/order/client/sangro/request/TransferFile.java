package org.zsoft.ecommerce.order.client.sangro.request;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlType;

@XmlRootElement(name = "TransferFile")
@XmlType(propOrder = { "sangroKundenNummer", "belege", "rueckmeldeDatum", "bestellungen" })
public class TransferFile {
  
  private String SangroKundenNummer;

  private String Belege;

  private String RueckmeldeDatum;

  private Bestellungen Bestellungen;
  
  @XmlElement(name = "SangroKundenNummer")
  public String getSangroKundenNummer ()
  {
      return SangroKundenNummer;
  }

  public void setSangroKundenNummer (String SangroKundenNummer)
  {
      this.SangroKundenNummer = SangroKundenNummer;
  }
  @XmlElement(name = "Belege")
  public String getBelege ()
  {
      return Belege;
  }

  public void setBelege (String Belege)
  {
      this.Belege = Belege;
  }

  public String getRueckmeldeDatum ()
  {
      return RueckmeldeDatum;
  }

  public void setRueckmeldeDatum (String RueckmeldeDatum)
  {
      this.RueckmeldeDatum = RueckmeldeDatum;
  }
  
  @XmlElement(name = "Bestellungen")
  public Bestellungen getBestellungen ()
  {
      return Bestellungen;
  }

  public void setBestellungen (Bestellungen Bestellungen)
  {
      this.Bestellungen = Bestellungen;
  }

  

  @Override
  public String toString()
  {
      return "ClassPojo [Belege = "+Belege+", RueckmeldeDatum = "+RueckmeldeDatum+", Bestellungen = "+Bestellungen+", SangroKundenNummer = "+SangroKundenNummer+"]";
  }
}
