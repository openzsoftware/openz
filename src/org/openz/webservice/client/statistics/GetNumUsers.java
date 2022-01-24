package org.openz.webservice.client.statistics;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import org.openbravo.base.secureApp.DefaultOptionsData;
import org.openbravo.database.ConnectionProvider;
import org.openbravo.utils.CryptoSHA1BASE64;

public class GetNumUsers {
	
	public static int checkAndGo(String orgid,ConnectionProvider conn) throws Exception {

		CheckLicenseServiceSoapBindingStub binding;
		binding = (CheckLicenseServiceSoapBindingStub)
                new CheckLicenseServiceServiceLocator().getCheckLicenseService();
		binding.setTimeout(60000);
		int numof = binding.numOfUsersLicensed(orgid);
		if (numof==-1)  {
			DefaultOptionsData.setActivationKey(conn,"","");
			DefaultOptionsData.setUsers(conn, "2");
		} else { 
			DefaultOptionsData.setActivationKey(conn,Integer.toString(numof),CryptoSHA1BASE64.hash(orgid));
			DefaultOptionsData.setUsers(conn, Integer.toString(numof));
			DefaultOptionsData.DeActivateAdv(conn);
			DefaultOptionsData.ActivateAdv(conn);
		}
		return numof;
		
	}
	
}
