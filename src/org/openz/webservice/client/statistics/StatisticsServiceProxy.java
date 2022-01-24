package org.openz.webservice.client.statistics;

public class StatisticsServiceProxy implements org.openz.webservice.client.statistics.StatisticsService {
  private String _endpoint = null;
  private org.openz.webservice.client.statistics.StatisticsService statisticsService = null;
  
  public StatisticsServiceProxy() {
    _initStatisticsServiceProxy();
  }
  
  public StatisticsServiceProxy(String endpoint) {
    _endpoint = endpoint;
    _initStatisticsServiceProxy();
  }
  
  private void _initStatisticsServiceProxy() {
    try {
      statisticsService = (new org.openz.webservice.client.statistics.StatisticsServiceServiceLocator()).getStatisticsService();
      if (statisticsService != null) {
        if (_endpoint != null)
          ((javax.xml.rpc.Stub)statisticsService)._setProperty("javax.xml.rpc.service.endpoint.address", _endpoint);
        else
          _endpoint = (String)((javax.xml.rpc.Stub)statisticsService)._getProperty("javax.xml.rpc.service.endpoint.address");
      }
      
    }
    catch (javax.xml.rpc.ServiceException serviceException) {}
  }
  
  public String getEndpoint() {
    return _endpoint;
  }
  
  public void setEndpoint(String endpoint) {
    _endpoint = endpoint;
    if (statisticsService != null)
      ((javax.xml.rpc.Stub)statisticsService)._setProperty("javax.xml.rpc.service.endpoint.address", _endpoint);
    
  }
  
  public org.openz.webservice.client.statistics.StatisticsService getStatisticsService() {
    if (statisticsService == null)
      _initStatisticsServiceProxy();
    return statisticsService;
  }
  
  public int insertStatistics(java.lang.String p_orgcount, java.lang.String orgready, java.lang.String p_facts, java.lang.String p_orders, java.lang.String p_invoices, java.lang.String p_inouts, java.lang.String p_products, java.lang.String p_projects, java.lang.String p_bpartners, java.lang.String p_crms, java.lang.String p_numofusers, java.lang.String p_anonyminstancekey) throws java.rmi.RemoteException{
    if (statisticsService == null)
      _initStatisticsServiceProxy();
    return statisticsService.insertStatistics(p_orgcount, orgready, p_facts, p_orders, p_invoices, p_inouts, p_products, p_projects, p_bpartners, p_crms, p_numofusers, p_anonyminstancekey);
  }
  
  
}
