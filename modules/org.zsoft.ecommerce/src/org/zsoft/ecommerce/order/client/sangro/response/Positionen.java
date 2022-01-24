package org.zsoft.ecommerce.order.client.sangro.response;

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
}
