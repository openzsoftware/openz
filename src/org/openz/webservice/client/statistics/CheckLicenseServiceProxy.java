package org.openz.webservice.client.statistics;

public class CheckLicenseServiceProxy implements org.openz.webservice.client.statistics.CheckLicenseService {
  private String _endpoint = null;
  private org.openz.webservice.client.statistics.CheckLicenseService checkLicenseService = null;
  
  public CheckLicenseServiceProxy() {
    _initCheckLicenseServiceProxy();
  }
  
  public CheckLicenseServiceProxy(String endpoint) {
    _endpoint = endpoint;
    _initCheckLicenseServiceProxy();
  }
  
  private void _initCheckLicenseServiceProxy() {
    try {
      checkLicenseService = (new org.openz.webservice.client.statistics.CheckLicenseServiceServiceLocator()).getCheckLicenseService();
      if (checkLicenseService != null) {
        if (_endpoint != null)
          ((javax.xml.rpc.Stub)checkLicenseService)._setProperty("javax.xml.rpc.service.endpoint.address", _endpoint);
        else
          _endpoint = (String)((javax.xml.rpc.Stub)checkLicenseService)._getProperty("javax.xml.rpc.service.endpoint.address");
      }
      
    }
    catch (javax.xml.rpc.ServiceException serviceException) {}
  }
  
  public String getEndpoint() {
    return _endpoint;
  }
  
  public void setEndpoint(String endpoint) {
    _endpoint = endpoint;
    if (checkLicenseService != null)
      ((javax.xml.rpc.Stub)checkLicenseService)._setProperty("javax.xml.rpc.service.endpoint.address", _endpoint);
    
  }
  
  public org.openz.webservice.client.statistics.CheckLicenseService getCheckLicenseService() {
    if (checkLicenseService == null)
      _initCheckLicenseServiceProxy();
    return checkLicenseService;
  }
  
  public int numOfUsersLicensed(java.lang.String guuid) throws java.rmi.RemoteException{
    if (checkLicenseService == null)
      _initCheckLicenseServiceProxy();
    return checkLicenseService.numOfUsersLicensed(guuid);
  }
  
  
}
