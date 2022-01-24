package org.zsoft.ecommerce.order.client.sangro.request;

import javax.xml.bind.annotation.XmlElement;

public class Positionen {
  private Position[] Position;
  @XmlElement(name = "Position")
  public Position[] getPosition ()
  {
      return Position;
  }

  public void setPosition (Position[] Position)
  {
      this.Position = Position;
  }

  @Override
  public String toString()
  {
      return "ClassPojo [Position = "+Position+"]";
  }
}
