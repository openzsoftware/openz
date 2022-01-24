package org.zsoft.ecommerce.order.client.emporium.request;

import javax.xml.bind.annotation.XmlElement;

public class OrderEntry
{
    private OrderlinesEmporium orderlines;

    private String company_id;

    private String relatiecode;

    private String hb_datum;

    private String controle_code;
    
    private Htgaovrelatie htg_aov_relatie;

    private String klantnummer;

    private String budu;

    private String diverse_jn_velden;

    private String boeker;

    private String document_type;

    private String kenmerk;

    private String externe_reeks;

    private String source;

    private String hb_tijd;

    private String haal_breng;

    private String record_type2;

    private String record_type1;

    public OrderlinesEmporium getOrderlines ()
    {
        return orderlines;
    }

    public void setOrderlines (OrderlinesEmporium orderlines)
    {
        this.orderlines = orderlines;
    }

    public String getCompany_id ()
    {
        return company_id;
    }

    public void setCompany_id (String company_id)
    {
        this.company_id = company_id;
    }

    public String getRelatiecode ()
    {
        return relatiecode;
    }

    public void setRelatiecode (String relatiecode)
    {
        this.relatiecode = relatiecode;
    }

    public String getHb_datum ()
    {
        return hb_datum;
    }

    public void setHb_datum (String hb_datum)
    {
        this.hb_datum = hb_datum;
    }

    public String getControle_code ()
    {
        return controle_code;
    }

    public void setControle_code (String controle_code)
    {
        this.controle_code = controle_code;
    }

    public Htgaovrelatie getHtgaovrelatie ()
    {
        return htg_aov_relatie;
    }
    @XmlElement(name = "Htgaovrelatie")

    public void setHtgaovrelatie (Htgaovrelatie htg_aov_relatie)
    {
        this.htg_aov_relatie = htg_aov_relatie;
    }

    public String getKlantnummer ()
    {
        return klantnummer;
    }

    public void setKlantnummer (String klantnummer)
    {
        this.klantnummer = klantnummer;
    }

    public String getBudu ()
    {
        return budu;
    }

    public void setBudu (String budu)
    {
        this.budu = budu;
    }

    public String getDiverse_jn_velden ()
    {
        return diverse_jn_velden;
    }

    public void setDiverse_jn_velden (String diverse_jn_velden)
    {
        this.diverse_jn_velden = diverse_jn_velden;
    }

    public String getBoeker ()
    {
        return boeker;
    }

    public void setBoeker (String boeker)
    {
        this.boeker = boeker;
    }

    public String getDocument_type ()
    {
        return document_type;
    }

    public void setDocument_type (String document_type)
    {
        this.document_type = document_type;
    }

    public String getKenmerk ()
    {
        return kenmerk;
    }

    public void setKenmerk (String kenmerk)
    {
        this.kenmerk = kenmerk;
    }

    public String getExterne_reeks ()
    {
        return externe_reeks;
    }

    public void setExterne_reeks (String externe_reeks)
    {
        this.externe_reeks = externe_reeks;
    }

    public String getSource ()
    {
        return source;
    }

    public void setSource (String source)
    {
        this.source = source;
    }

    public String getHb_tijd ()
    {
        return hb_tijd;
    }

    public void setHb_tijd (String hb_tijd)
    {
        this.hb_tijd = hb_tijd;
    }

    public String getHaal_breng ()
    {
        return haal_breng;
    }

    public void setHaal_breng (String haal_breng)
    {
        this.haal_breng = haal_breng;
    }

    public String getRecord_type2 ()
    {
        return record_type2;
    }

    public void setRecord_type2 (String record_type2)
    {
        this.record_type2 = record_type2;
    }

    public String getRecord_type1 ()
    {
        return record_type1;
    }

    public void setRecord_type1 (String record_type1)
    {
        this.record_type1 = record_type1;
    }

    @Override
    public String toString()
    {
        return "ClassPojo [orderlines = "+orderlines+", company_id = "+company_id+", relatiecode = "+relatiecode+", hb_datum = "+hb_datum+", controle_code = "+controle_code+", htg_aov_relatie = "+htg_aov_relatie+", klantnummer = "+klantnummer+", budu = "+budu+", diverse_jn_velden = "+diverse_jn_velden+", boeker = "+boeker+", document_type = "+document_type+", kenmerk = "+kenmerk+", externe_reeks = "+externe_reeks+", source = "+source+", hb_tijd = "+hb_tijd+", haal_breng = "+haal_breng+", record_type2 = "+record_type2+", record_type1 = "+record_type1+"]";
    }
}