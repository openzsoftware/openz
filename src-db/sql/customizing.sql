CREATE OR REPLACE FUNCTION zssi_smartinvoiceprefs_trg()
  RETURNS trigger AS
$BODY$ DECLARE 

/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Smartprefs
Ony one Pref per org/type
****************************************************/
v_total              numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN  RETURN NEW; END IF; 
  if new.zse_shop_id is not null then -- Shop Order
    select  count(*) into v_total from zssi_smartinvoiceprefs where  zse_shop_id=new.zse_shop_id  and zssi_smartinvoiceprefs_id!=COALESCE(new.zssi_smartinvoiceprefs_id,'0');
    if v_total > 0 and new.isactive='Y' then
        new.isactive='N';
        RAISE EXCEPTION '%', '@zssi_OnlyOneSetInSIP@';
    end if;
    if COALESCE(new.invoicetype,'0')!='SSO' then
        RAISE EXCEPTION '%', 'Only Webshop-Orders can be defined for shops';
    end if;
  else
    select count(*) into v_total from zssi_smartinvoiceprefs where ad_org_id=new.ad_org_id and ad_client_id=new.ad_client_id and invoicetype=new.invoicetype and isactive='Y' 
                                and zssi_smartinvoiceprefs_id!=COALESCE(new.zssi_smartinvoiceprefs_id,'0') and zse_shop_id is null;
    if v_total > 0 and new.isactive='Y' then
        new.isactive='N';
        RAISE EXCEPTION '%', '@zssi_OnlyOneSetInSIP@';
    end if;
  end if;
RETURN NEW;
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
ALTER FUNCTION zssi_smartinvoiceprefs_trg() OWNER TO tad;

 
