package org.zsoft.ecommerce.product.client.emporium.response;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;


public class Stock
{
    private String Time;

    private Product[] Product;

    private String Date;
    @XmlElement(name = "Time")
    public String getTime ()
    {
        return Time;
    }

    public void setTime (String Time)
    {
        this.Time = Time;
    }
    @XmlElement(name = "product")
    public Product[] getProduct ()
    {
        return Product;
    }
    
    public void setProduct (Product[] Product)
    {
        this.Product = Product;
    }
    @XmlElement(name = "date")
    public String getDate ()
    {
        return Date;
    }

    public void setDate (String Date)
    {
        this.Date = Date;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [Time = "+Time+", Product = "+Product+", Date = "+Date+"]";
    }
}