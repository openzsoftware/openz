package org.zsoft.ecommerce.order.client.attends.request;

import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "Sv97daten")
public class Sv97daten {

private Sv97kopf sv97kopf;

private Sv97position sv97position;

public Sv97kopf getSv97kopf ()
{
    return sv97kopf;
}

public void setSv97kopf (Sv97kopf sv97kopf)
{
    this.sv97kopf = sv97kopf;
}

public Sv97position getSv97position ()
{
    return sv97position;
}

public void setSv97position (Sv97position sv97position)
{
    this.sv97position = sv97position;
}
}
