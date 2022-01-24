package org.zsoft.ecommerce.product.client.emporium.response;

import javax.xml.bind.annotation.XmlElement;

public class Product
{
    private String Barcode;

    private String Brand;

    private org.zsoft.ecommerce.product.client.emporium.response.ProductTranslation[] ProductTranslation;

    private String Type;

    private String ArticleNumber;

    private String SuggestedSalesPrice;

    private String Weight;

    private String Assortment;

    private String AvailableStock;

    private String ExternalArticleNumber;

    private String Width;

    private String UsedFor;

    private String Version;

    private String Currency;

    private String AdditionalProductInformation;

    private String Sort;

    private String Description;

    private String Height;

    private String SuggestedRetailPrice;

    private String BrandLine;

    private String StockType;

    private String Concern;

    private String Color;

    private String Weight_UnitOfMeasurement;

    private String Category;

    private String CategoryDescription;

    private String Edition;

    private String Length;

    private String Gender;

    private String Price;

    private String Reference;
    @XmlElement(name = "Barcode")
    public String getBarcode ()
    {
        return Barcode;
    }

    public void setBarcode (String Barcode)
    {
        this.Barcode = Barcode;
    }
    @XmlElement(name = "Brand")
    public String getBrand ()
    {
        return Brand;
    }

    public void setBrand (String Brand)
    {
        this.Brand = Brand;
    }
    @XmlElement(name = "ProductTranslation")
    public ProductTranslation [] getProductTranslation ()
    {
        return ProductTranslation;
    }

    public void setProductTranslation (org.zsoft.ecommerce.product.client.emporium.response.ProductTranslation[] ProductTranslation)
    {
        this.ProductTranslation = ProductTranslation;
    }
    @XmlElement(name = "Type")
    public String getType ()
    {
        return Type;
    }

    public void setType (String Type)
    {
        this.Type = Type;
    }
    @XmlElement(name = "ArticleNumber")
    public String getArticleNumber ()
    {
        return ArticleNumber;
    }

    public void setArticleNumber (String ArticleNumber)
    {
        this.ArticleNumber = ArticleNumber;
    }
    @XmlElement(name = "SuggestedSalesPrice")
    public String getSuggestedSalesPrice ()
    {
        return SuggestedSalesPrice;
    }

    public void setSuggestedSalesPrice (String SuggestedSalesPrice)
    {
        this.SuggestedSalesPrice = SuggestedSalesPrice;
    }
    @XmlElement(name = "Weight")
    public String getWeight ()
    {
        return Weight;
    }

    public void setWeight (String Weight)
    {
        this.Weight = Weight;
    }
    @XmlElement(name = "Assortment")
    public String getAssortment ()
    {
        return Assortment;
    }

    public void setAssortment (String Assortment)
    {
        this.Assortment = Assortment;
    }
    @XmlElement(name = "AvailableStock")
    public String getAvailableStock ()
    {
        return AvailableStock;
    }

    public void setAvailableStock (String AvailableStock)
    {
        this.AvailableStock = AvailableStock;
    }
    @XmlElement(name = "ExternalArticleNumber")
    public String getExternalArticleNumber ()
    {
        return ExternalArticleNumber;
    }

    public void setExternalArticleNumber (String ExternalArticleNumber)
    {
        this.ExternalArticleNumber = ExternalArticleNumber;
    }
    @XmlElement(name = "Width")
    public String getWidth ()
    {
        return Width;
    }

    public void setWidth (String Width)
    {
        this.Width = Width;
    }
    @XmlElement(name = "UsedFor")
    public String getUsedFor ()
    {
        return UsedFor;
    }

    public void setUsedFor (String UsedFor)
    {
        this.UsedFor = UsedFor;
    }
    @XmlElement(name = "Version")
    public String getVersion ()
    {
        return Version;
    }

    public void setVersion (String Version)
    {
        this.Version = Version;
    }
    @XmlElement(name = "Currency")
    public String getCurrency ()
    {
        return Currency;
    }

    public void setCurrency (String Currency)
    {
        this.Currency = Currency;
    }
    @XmlElement(name = "AdditionalProductInformation")
    public String getAdditionalProductInformation ()
    {
        return AdditionalProductInformation;
    }

    public void setAdditionalProductInformation (String AdditionalProductInformation)
    {
        this.AdditionalProductInformation = AdditionalProductInformation;
    }
    @XmlElement(name = "Sort")
    public String getSort ()
    {
        return Sort;
    }

    public void setSort (String Sort)
    {
        this.Sort = Sort;
    }
    @XmlElement(name = "Description")
    public String getDescription ()
    {
        return Description;
    }

    public void setDescription (String Description)
    {
        this.Description = Description;
    }
    @XmlElement(name = "Height")
    public String getHeight ()
    {
        return Height;
    }

    public void setHeight (String Height)
    {
        this.Height = Height;
    }
    @XmlElement(name = "SuggestedRetailPrice")
    public String getSuggestedRetailPrice ()
    {
        return SuggestedRetailPrice;
    }

    public void setSuggestedRetailPrice (String SuggestedRetailPrice)
    {
        this.SuggestedRetailPrice = SuggestedRetailPrice;
    }
    @XmlElement(name = "BrandLine")
    public String getBrandLine ()
    {
        return BrandLine;
    }

    public void setBrandLine (String BrandLine)
    {
        this.BrandLine = BrandLine;
    }
    @XmlElement(name = "StockType")
    public String getStockType ()
    {
        return StockType;
    }

    public void setStockType (String StockType)
    {
        this.StockType = StockType;
    }
    @XmlElement(name = "Concern")
    public String getConcern ()
    {
        return Concern;
    }

    public void setConcern (String Concern)
    {
        this.Concern = Concern;
    }
    @XmlElement(name = "Color")
    public String getColor ()
    {
        return Color;
    }

    public void setColor (String Color)
    {
        this.Color = Color;
    }
    @XmlElement(name = "WeigthUnitOfMeasurment")
    public String getWeight_UnitOfMeasurement ()
    {
        return Weight_UnitOfMeasurement;
    }

    public void setWeight_UnitOfMeasurement (String Weight_UnitOfMeasurement)
    {
        this.Weight_UnitOfMeasurement = Weight_UnitOfMeasurement;
    }
    @XmlElement(name = "Category")
    public String getCategory ()
    {
        return Category;
    }

    public void setCategory (String Category)
    {
        this.Category = Category;
    }
    @XmlElement(name = "CategoryDescription")
    public String getCategoryDescription ()
    {
        return CategoryDescription;
    }

    public void setCategoryDescription (String CategoryDescription)
    {
        this.CategoryDescription = CategoryDescription;
    }
    @XmlElement(name = "Edition")
    public String getEdition ()
    {
        return Edition;
    }

    public void setEdition (String Edition)
    {
        this.Edition = Edition;
    }
    @XmlElement(name = "Length")
    public String getLength ()
    {
        return Length;
    }

    public void setLength (String Length)
    {
        this.Length = Length;
    }
    @XmlElement(name = "Gender")
    public String getGender ()
    {
        return Gender;
    }

    public void setGender (String Gender)
    {
        this.Gender = Gender;
    }
    @XmlElement(name = "Price")
    public String getPrice ()
    {
        return Price;
    }

    public void setPrice (String Price)
    {
        this.Price = Price;
    }
    @XmlElement(name = "Reference")
    public String getReference ()
    {
        return Reference;
    }

    public void setReference (String Reference)
    {
        this.Reference = Reference;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [Barcode = "+Barcode+", Brand = "+Brand+", ProductTranslation = "+ProductTranslation+", Type = "+Type+", ArticleNumber = "+ArticleNumber+", SuggestedSalesPrice = "+SuggestedSalesPrice+", Weight = "+Weight+", Assortment = "+Assortment+", AvailableStock = "+AvailableStock+", ExternalArticleNumber = "+ExternalArticleNumber+", Width = "+Width+", UsedFor = "+UsedFor+", Version = "+Version+", Currency = "+Currency+", AdditionalProductInformation = "+AdditionalProductInformation+", Sort = "+Sort+", Description = "+Description+", Height = "+Height+", SuggestedRetailPrice = "+SuggestedRetailPrice+", BrandLine = "+BrandLine+", StockType = "+StockType+", Concern = "+Concern+", Color = "+Color+", Weight_UnitOfMeasurement = "+Weight_UnitOfMeasurement+", Category = "+Category+", CategoryDescription = "+CategoryDescription+", Edition = "+Edition+", Length = "+Length+", Gender = "+Gender+", Price = "+Price+", Reference = "+Reference+"]";
    }
}