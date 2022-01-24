package org.zsoft.ecommerce.order.client.attends.response;

import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "sv97daten")
public class Sv97datenU {
  private Sv97image sv97image;

  

  public Sv97image getSv97image ()
  {
      return sv97image;
  }

  public void setSv97image (Sv97image sv97image)
  {
      this.sv97image = sv97image;
  }

}
