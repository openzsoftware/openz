package org.zsoft.ecommerce.order.client.attends.response;

import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "sv97daten")
public class Sv97daten {
  private Sv97dhl sv97dhl;

  private Sv97best sv97best;

  public Sv97dhl getSv97dhl ()
  {
      return sv97dhl;
  }

  public void setSv97dhl (Sv97dhl sv97dhl)
  {
      this.sv97dhl = sv97dhl;
  }

  public Sv97best getSv97best ()
  {
      return sv97best;
  }

  public void setSv97best (Sv97best sv97best)
  {
      this.sv97best = sv97best;
  }
}
