package org.zsoft.ecommerce.order.client.attends.response;

import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "sv97daten")
public class Sv97datenE {

  

  private Sv97fehler sv97fehler;

  private Sv97best sv97best;

  public Sv97fehler getSv97fehler ()
  {
      return sv97fehler;
  }

  public void setSv97fehler (Sv97fehler sv97fehler)
  {
      this.sv97fehler = sv97fehler;
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
