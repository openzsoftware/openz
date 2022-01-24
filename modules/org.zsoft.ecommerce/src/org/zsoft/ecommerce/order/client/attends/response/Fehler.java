package org.zsoft.ecommerce.order.client.attends.response;

public class Fehler {
  private String auftragnr;

  private String fehlermeldung;

  public String getAuftragnr ()
  {
      return auftragnr;
  }

  public void setAuftragnr (String auftragnr)
  {
      this.auftragnr = auftragnr;
  }

  public String getFehlermeldung ()
  {
      return fehlermeldung;
  }

  public void setFehlermeldung (String fehlermeldung)
  {
      this.fehlermeldung = fehlermeldung;
  }
}
