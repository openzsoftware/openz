package org.zsoft.ecommerce.order.client.emporium.request;
public class Htgaovorderregel
{
	private String extern_productnummer;

    private String aantal_besteld;

    private String record_type;

    private String Productnummer;

    private String valuta;

    private String partijnummer;

    private String magazijn;

    public String getExtern_productnummer ()
    {
        return extern_productnummer;
    }

    public void setExtern_productnummer (String extern_productnummer)
    {
        this.extern_productnummer = extern_productnummer;
    }

    public String getAantal_besteld ()
    {
        return aantal_besteld;
    }

    public void setAantal_besteld (String aantal_besteld)
    {
        this.aantal_besteld = aantal_besteld;
    }

    public String getRecord_type ()
    {
        return record_type;
    }

    public void setRecord_type (String record_type)
    {
        this.record_type = record_type;
    }

    public String getProductnummer ()
    {
        return Productnummer;
    }

    public void setProductnummer (String Productnummer)
    {
        this.Productnummer = Productnummer;
    }

    public String getValuta ()
    {
        return valuta;
    }

    public void setValuta (String valuta)
    {
        this.valuta = valuta;
    }

    public String getPartijnummer ()
    {
        return partijnummer;
    }

    public void setPartijnummer (String partijnummer)
    {
        this.partijnummer = partijnummer;
    }

    public String getMagazijn ()
    {
        return magazijn;
    }

    public void setMagazijn (String magazijn)
    {
        this.magazijn = magazijn;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [extern_productnummer = "+extern_productnummer+", aantal_besteld = "+aantal_besteld+", record_type = "+record_type+", Productnummer = "+Productnummer+", valuta = "+valuta+", partijnummer = "+partijnummer+", magazijn = "+magazijn+"]";
    }
}