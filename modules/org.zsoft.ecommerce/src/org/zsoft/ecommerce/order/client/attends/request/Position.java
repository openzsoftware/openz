package org.zsoft.ecommerce.order.client.attends.request;

public class Position {
  private String ean;

  private String gtin;

  private String auftragnr;

  private String menge;

  public String getEan ()
  {
      return ean;
  }

  public void setEan (String ean)
  {
      this.ean = ean;
  }

  public String getGtin ()
  {
      return gtin;
  }

  public void setGtin (String gtin)
  {
      this.gtin = gtin;
  }

  public String getAuftragnr ()
  {
      return auftragnr;
  }

  public void setAuftragnr (String auftragnr)
  {
      this.auftragnr = auftragnr;
  }

  public String getMenge ()
  {
      return menge;
  }

  public void setMenge (String menge)
  {
      this.menge = menge;
  }

}
