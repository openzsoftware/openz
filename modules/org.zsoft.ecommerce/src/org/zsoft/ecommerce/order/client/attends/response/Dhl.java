package org.zsoft.ecommerce.order.client.attends.response;

public class Dhl {
  private String dhlnr;

  private String auftragnr;

  private String paketdienst;

  public String getDhlnr ()
  {
      return dhlnr;
  }

  public void setDhlnr (String dhlnr)
  {
      this.dhlnr = dhlnr;
  }

  public String getAuftragnr ()
  {
      return auftragnr;
  }

  public void setAuftragnr (String auftragnr)
  {
      this.auftragnr = auftragnr;
  }

  public String getPaketdienst ()
  {
      return paketdienst;
  }

  public void setPaketdienst (String paketdienst)
  {
      this.paketdienst = paketdienst;
  }

}
