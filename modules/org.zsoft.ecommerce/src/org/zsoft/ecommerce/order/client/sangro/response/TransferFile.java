package org.zsoft.ecommerce.order.client.sangro.response;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "TransferFile")
public class TransferFile {
  private String RueckmeldeDatum;

  private Bestellungen Bestellungen;

  private String SangroKundenNummer;
  @XmlElement(name = "RueckmeldeDatum")
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
  @XmlElement(name = "SangroKundenNummer")
  public String getSangroKundenNummer ()
  {
      return SangroKundenNummer;
  }

  public void setSangroKundenNummer (String SangroKundenNummer)
  {
      this.SangroKundenNummer = SangroKundenNummer;
  }
}
