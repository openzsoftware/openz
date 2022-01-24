package org.zsoft.ecommerce.order.client.attends.response;


public class Image {
  private String dhlnr;

  private String auftragnr;

  private String lieferdatum_dhl;
  
  private String unterschrift;
  
  private String paketdienst;
  
  
  public void setUnterschrift (String unterschrift)
  {
      this.unterschrift = unterschrift;
  }
  public String getUnterschrift ()
  {
      return unterschrift;
  }
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

  public String getLieferdatum_dhl ()
  {
      return lieferdatum_dhl;
  }

  public void setLieferdatum_dhl (String lieferdatum_dhl)
  {
      this.lieferdatum_dhl = lieferdatum_dhl;
  }
  public String getPaketdienst ()
  {
      return paketdienst;
  }

  public void setPaketdienst (String paketdienst)
  {
      this.paketdienst=paketdienst;
  }

}
