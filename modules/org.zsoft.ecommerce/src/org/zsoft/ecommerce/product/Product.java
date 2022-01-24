/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
package org.zsoft.ecommerce.product;
import java.util.Date;
import java.math.BigDecimal;
import org.zsoft.ecommerce.*;

public class Product {
  private String  mProductId;
  
  public String getMProductId() {
       return mProductId;
  }
 
  public void setMProductId(String pmProductId) {
       mProductId = pmProductId;
  }
 

    private Date  lastupdated;
 
  public Date getLastupdated() {
       return lastupdated;
  }
 
  public void setLastupdated(Date plastupdated) {
       lastupdated = plastupdated;
  }
 
    private String  value;
 
  public String getValue() {
       return value;
  }
 
  public void setValue(String pvalue) {
       value = pvalue;
  }
 
    private String  name;
 
  public String getName() {
       return name;
  }
 
  public void setName(String pname) {
       name = pname;
  }
 
    private String  eancode;
 
  public String getEancode() {
       return eancode;
  }
 
  public void setEancode(String peancode) {
       eancode = peancode;
  }

  private String  description;
  
public String getDescription() {
    return description;
}

public void setDescription(String pdescription) {
    description = pdescription;
}

 private String  documentnote;

public String getDocumentnote() {
    return documentnote;
}

public void setDocumentnote(String pdocumentnote) {
    documentnote = pdocumentnote;
}

 private String  productCategoryKey;

public String getProductCategoryKey() {
    return productCategoryKey;
}

public void setProductCategoryKey(String pproductCategoryKey) {
    productCategoryKey = pproductCategoryKey;
}

 private String  uomKey;

public String getUomKey() {
    return uomKey;
}

public void setUomKey(String puomKey) {
    uomKey = puomKey;
}

 private String  isfreightproduct;

public String getIsfreightproduct() {
    return isfreightproduct;
}
public void setIsfreightproduct(String pisfreightproduct) {
  isfreightproduct = pisfreightproduct;
}

private BigDecimal  weight;

public BigDecimal getWeight() {
  return weight;
}

public void setWeight(BigDecimal pweight) {
  weight = pweight;
}

private String  imageurl;

public String getImageurl() {
  return imageurl;
}

public void setImageurl(String pimageurl) {
  imageurl = pimageurl;
}

private String  descriptionurl;

public String getDescriptionurl() {
  return descriptionurl;
}

public void setDescriptionurl(String pdescriptionurl) {
  descriptionurl = pdescriptionurl;
}
private String  eccategory;

public String getECommerceCategory() {
  return eccategory;
}

public void setECommerceCategory(String peccategory) {
  eccategory = peccategory;
}

private BigDecimal ecommercepriority;

public BigDecimal getECommercePriority() {
  return ecommercepriority;
}

public void setECommercePriority(BigDecimal ppriority) {
  ecommercepriority = ppriority;
}

private BigDecimal taxrate;

public BigDecimal getTaxrate() {
  return taxrate;
}

public void setTaxrate(BigDecimal ptaxrate) {
  taxrate = ptaxrate;
}
private String  isgrossprice;

public String getIsgrossprice() {
    return isgrossprice;
}
public void setIsgrossprice(String pisgrossprice) {
  isgrossprice = pisgrossprice;
}
private String  isorderable;

public String getIsorderable() {
    return isorderable;
}
public void setIsorderable(String pisorderable) {
  isorderable = pisorderable;
}

private String  taxname;

public String getTaxname() {
    return taxname;
}
public void setTaxname(String ptaxname) {
  taxname = ptaxname;
}

private BigDecimal stdprice;

public BigDecimal getStdprice() {
  return stdprice;
}

public void setStdprice(BigDecimal pstdprice) {
  stdprice = pstdprice;
}

private ProductTranslation[] translations;

public ProductTranslation[] getTranslations() {
  return translations;
}

public void setTranslations(ProductTranslation[] value) {
  translations = value;
}

}
