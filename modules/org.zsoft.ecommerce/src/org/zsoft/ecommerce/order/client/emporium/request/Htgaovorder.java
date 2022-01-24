package org.zsoft.ecommerce.order.client.emporium.request;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;
@XmlRootElement(name = "htg_aov_order")
public class Htgaovorder
{
    private OrderEntry order;
    
    @XmlElement(name = "order")
    public OrderEntry getOrder ()
    {
        return order;
    }

    public void setOrder (OrderEntry order)
    {
        this.order = order;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [order = "+order+"]";
    }
}