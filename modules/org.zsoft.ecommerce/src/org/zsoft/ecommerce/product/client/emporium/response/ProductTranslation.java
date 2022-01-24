package org.zsoft.ecommerce.product.client.emporium.response;

import javax.xml.bind.annotation.XmlElement;

public class ProductTranslation
{
    private String ProductExtendedDescription;

    private String LanguageCode;

    private String ProductShortDescription;

    private String ProductDescription;

    private String ExtendedDescription;

    private String ProductSortDescription;
    @XmlElement(name = "ProductExtendedDescription")
    public String getProductExtendedDescription ()
    {
        return ProductExtendedDescription;
    }

    public void setProductExtendedDescription (String ProductExtendedDescription)
    {
        this.ProductExtendedDescription = ProductExtendedDescription;
    }
    @XmlElement(name = "LanguageCode")
    public String getLanguageCode ()
    {
        return LanguageCode;
    }

    public void setLanguageCode (String LanguageCode)
    {
        this.LanguageCode = LanguageCode;
    }
    @XmlElement(name = "ProductShortDescription")
    public String getProductShortDescription ()
    {
        return ProductShortDescription;
    }

    public void setProductShortDescription (String ProductShortDescription)
    {
        this.ProductShortDescription = ProductShortDescription;
    }
    @XmlElement(name = "ProductDescription")
    public String getProductDescription ()
    {
        return ProductDescription;
    }

    public void setProductDescription (String ProductDescription)
    {
        this.ProductDescription = ProductDescription;
    }
    @XmlElement(name = "ExtendedDescription")
    public String getExtendedDescription ()
    {
        return ExtendedDescription;
    }

    public void setExtendedDescription (String ExtendedDescription)
    {
        this.ExtendedDescription = ExtendedDescription;
    }
    @XmlElement(name = "ProductSortDescription")
    public String getProductSortDescription ()
    {
        return ProductSortDescription;
    }

    public void setProductSortDescription (String ProductSortDescription)
    {
        this.ProductSortDescription = ProductSortDescription;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [ProductExtendedDescription = "+ProductExtendedDescription+", LanguageCode = "+LanguageCode+", ProductShortDescription = "+ProductShortDescription+", ProductDescription = "+ProductDescription+", ExtendedDescription = "+ExtendedDescription+", ProductSortDescription = "+ProductSortDescription+"]";
    }
}