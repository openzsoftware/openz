package org.zsoft.ecommerce.order.client.emporium.request;
public class OrderlinesEmporium
{
	private Htgaovorderregel[] htg_aov_orderregel;

    public Htgaovorderregel[] getHtg_aov_orderregel ()
    {
        return htg_aov_orderregel;
    }

    public void setHtgaovorderregel (Htgaovorderregel [] htg_aov_orderregel)
    {
        this.htg_aov_orderregel = htg_aov_orderregel;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [htg_aov_orderregel = "+htg_aov_orderregel+"]";
    }
}