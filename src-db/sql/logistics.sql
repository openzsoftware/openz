SELECT zsse_dropfunction('zse_getparcelinfo'); 

CREATE OR REPLACE FUNCTION zse_getparcelinfo(p_inout_id varchar, OUT p_weight numeric, OUT p_parcelno numeric,OUT p_description varchar, OUT p_allValuesEmpty boolean) RETURNS setof record
AS $_$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Danny Heuduk (dh@openz.de)
Copyright (C) 2016 Danny Heuduk All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

*****************************************************/
v_cur record;
v_i numeric;
v_parcelno numeric:=1;
v_currentpn numeric:=0;
v_currentweight numeric:=0;
v_allValuesEmpty boolean := TRUE;
v_next varchar:='N';
v_decription varchar;
BEGIN 
     select min(coalesce(zse_parcelno,0)) into v_parcelno from m_inoutline where m_inout_id=p_inout_id and  zse_parcelqty is  null  ;
     
     for v_cur in (select coalesce(zse_parcelno,0) as zse_parcelno,zse_parcelweight,description from m_inoutline where m_inout_id=p_inout_id and  zse_parcelqty is  null order by coalesce(zse_parcelno,0))
     LOOP
          if (coalesce(v_cur.zse_parcelno,0)>v_parcelno) then
                 p_weight := v_currentweight;
                 p_parcelno:=v_parcelno;
                 p_description:=v_decription;
                 return next;
                  v_currentweight:=coalesce(v_cur.zse_parcelweight,0);
                  v_parcelno:=coalesce(v_cur.zse_parcelno,0);
                  v_decription:=v_cur.description;
          else
                  v_currentweight:=v_currentweight+coalesce(v_cur.zse_parcelweight,0);
                  v_decription:=v_cur.description;

		  if(v_currentweight != 0) then
			v_allValuesEmpty = FALSE;
		  end if;

                  v_next:='Y';
          end if;
     END LOOP;
     if v_next='Y' then
              p_parcelno:=v_parcelno;
              p_weight := v_currentweight;
              p_description:=v_decription;
	      p_allValuesEmpty:=v_allValuesEmpty;
              return next;
     end if;
     for v_cur in (select zse_parcelqty,zse_parcelweight,description   from m_inoutline where m_inout_id=p_inout_id and  zse_parcelqty is not null)
     LOOP
             for v_i in 1..v_cur.zse_parcelqty 
                     LOOP
                              v_currentpn:=coalesce(v_parcelno,0)+1;
                              p_description:=v_cur.description;
                              p_weight:=coalesce(v_cur.zse_parcelweight,0);
                              p_parcelno:=v_currentpn;

			      if(p_weight != 0) then
				p_allValuesEmpty = FALSE;
			      end if;

                              return next;
                     END LOOP;
     END LOOP;     
END;
$_$  LANGUAGE 'plpgsql';

select zsse_dropfunction('zse_getadresspart');
CREATE or replace FUNCTION zse_getadresspart(p_adress character varying, p_lang character varying,OUT p_street character varying,Out p_houseno character varying, OUT p_district character varying) RETURNS record
/***************************************************************************************************************************************************

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in



compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the

License for the specific language governing rights and limitations under the License.

The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)

Copyright (C) 2017 Danny Heuduk  All Rights Reserved.

Contributor(s): Danny Heuduk, Robert Schardt

***************************************************************************************************************************************************

Part of Smartprefs

Adress splitting made easy

*****************************************************/
AS $_$
DECLARE
     v_reg character varying ;
     v_filtered character varying;
     v_return character varying:= 'null';
     v_splitThis character varying;
BEGIN

    if p_lang='de_DE' 
	then v_reg:=' ([\d]+([\ \/\-\,]?[\d]*){0,4}[\ \/\-\,]?([a-zA-Z]{0,3}([\ ]|$)))';

    elsif p_lang='en_US'
	then v_reg:='(^\d+\w*\s*(?:(?:[\-\/]?\s*)?\d*(?:\s*\d+\/\s*)?\d+)?\s+)';

    elsif p_lang='fr_FR'
	then v_reg:='(^\d+\w*\s*(?:(?:[\-\/]?\s*)?\d*(?:\s*\d+\/\s*)?\d+)?\s+)';

    else 

    	p_street:='';
        p_houseno:='';

	Return;

    end if;

	    v_splitThis:=(select regexp_replace(p_adress, v_reg, '#'));

            p_street:=(select split_part(v_splitThis, '#', 1));
	    p_district:=(select split_part(v_splitThis, '#', 2));

	    if(p_street = '') then
		 p_street := p_district;
		 p_district := '';
	    end if;

            p_houseno:= replace(p_adress,p_street,'');
	    p_houseno:= replace(p_houseno,p_district,'');

        Return;
END;

$_$

  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
select zsse_droptrigger('zse_minoutline_bef_trg','m_inoutline');

  
CREATE OR REPLACE FUNCTION zse_minoutline_bef_trg()
  RETURNS trigger AS
$BODY$ DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2016 Stefan Zimmermann All Rights Reserved.
Contributor(s): Robert Schardt.
***************************************************************************************************************************************************
*/
v_inout_id varchar;
v_parcels numeric;
v_tmpparcels numeric;
v_oldweight numeric:=0;
v_tmpweight numeric:=0;
v_tmpMinoutWeight numeric := null;
v_totalWeight numeric;
v_allValuesEmpty boolean;
v_cur record;
v_minout_updated timestamp without time zone;
BEGIN
 
   IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF; 

    IF TG_OP != 'DELETE' then
             v_inout_id:=new.m_inout_id;
    else        
             v_inout_id:=old.m_inout_id;
    end if;

    select count(*), sum(p_weight), COALESCE(bool_and(p_allValuesEmpty), TRUE) into v_tmpparcels, v_tmpweight, v_allValuesEmpty 
	from zse_getparcelinfo(v_inout_id);

    select weight into v_tmpMinoutWeight from m_inout where m_inout_id = v_inout_id;
    v_tmpweight := COALESCE(v_tmpweight, 0);
 
    IF TG_OP = 'INSERT' then       
             if new.zse_parcelweight is null then
		select CASE WHEN weight=null then null else m_product_weight(m_product_id)*new. movementqty end into new.zse_parcelweight from m_product where m_product_id=new.m_product_id;
             end if;

	     if(0 = COALESCE(new.zse_parcelweight, 0) AND v_allValuesEmpty) then
		v_tmpweight := v_tmpMinoutWeight; 

	     else
                v_parcels:=v_tmpparcels;
                v_parcels:=v_parcels+coalesce(new.zse_parcelqty,0);
                v_tmpweight:=v_tmpweight+(coalesce(new.zse_parcelqty,1)*coalesce(new.zse_parcelweight,0));
	     end if;
    end if;

    IF TG_OP = 'DELETE' then           

	     if(v_allValuesEmpty) then
		v_tmpweight := null;

	     else
                v_parcels:=v_tmpparcels-coalesce(old.zse_parcelqty,0);
                v_oldweight:=(coalesce(old.zse_parcelqty,1)*coalesce(old.zse_parcelweight,0));
                v_tmpweight:=v_tmpweight-v_oldweight;
	     end if;
    end if;

    IF TG_OP = 'UPDATE' then    

       select updated into v_minout_updated from m_inout where m_inout_id = v_inout_id;

       -- wenn (das Gesamt-Gewicht aus m_inout jünger) und (old.- und new.weight von m_inout_line sind gleich)
       -- dann benutze dieses 
       if ((COALESCE(old.zse_parcelweight, 0) = COALESCE(new.zse_parcelweight, 0)) AND ((v_minout_updated > old.updated) OR v_allValuesEmpty)) then
	     v_tmpweight := v_tmpMinoutWeight; 

       -- wenn (old.- und new.weight gleich) und (alle Werte in m_inoutlines 0 oder null)
       -- dann setze m_inout.weight auf null
       elsif((COALESCE(old.zse_parcelweight, 0) = COALESCE(new.zse_parcelweight, 0)) AND v_allValuesEmpty) then
	     v_tmpweight := null;	

       -- wenn (das Gesamt-Gewicht aus m_inout älter) und (die Werte in m_inoutlines nicht null oder null)
       -- dann berechne das Gesamt-Gewicht aus den Positionen
       else

         if new.m_product_id!=old.m_product_id or new. movementqty!=old.movementqty then
                        select  m_product_weight(m_product_id)*new. movementqty into new.zse_parcelweight from m_product where m_product_id=new.m_product_id;
         end if;
    
         v_parcels:=v_tmpparcels-coalesce(old.zse_parcelqty,0);
         v_parcels:=v_parcels+coalesce(new.zse_parcelqty,0);
    
         v_oldweight:=(coalesce(old.zse_parcelqty,1)*coalesce(old.zse_parcelweight,0));
         v_tmpweight:=v_tmpweight-v_oldweight;
         v_tmpweight:=v_tmpweight+(coalesce(new.zse_parcelqty,1)*coalesce(new.zse_parcelweight,0));
       end if;
    end if;

    v_totalWeight := v_tmpweight;
    Update m_inout
        set weight=v_totalWeight,
        qtyofpallets=v_parcels
     where m_inout_id=v_inout_id; 
    -- Product weight on insert/update 
    IF TG_OP = 'INSERT' then
        if new.weight is null then
            select m_product_weight(m_product_id)*new.movementqty into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
    end if;
    IF TG_OP = 'UPDATE' then
        if coalesce(new.weight,0)=coalesce(old.weight,0) and (new.m_product_id!=old.m_product_id or new.movementqty!=old.movementqty) then
            select m_product_weight(m_product_id)*new.movementqty  into new.weight from m_product where m_product_id=new.m_product_id;
        end if;
    end if;
    IF TG_OP = 'DELETE' then RETURN OLD; else RETURN NEW; end if;
END;
  $BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
  
CREATE TRIGGER zse_minoutline_bef_trg
  BEFORE INSERT or UPDATE OR DELETE
  ON m_inoutline
  FOR EACH ROW
  EXECUTE PROCEDURE zse_minoutline_bef_trg();
