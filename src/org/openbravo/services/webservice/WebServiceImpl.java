/**
 * WebServiceImpl.java
 *
 * This file was auto-generated from WSDL
 * by the Apache Axis 1.4 Apr 22, 2006 (06:55:48 PDT) WSDL2Java emitter.
 */

package org.openbravo.services.webservice;

public interface WebServiceImpl extends java.rmi.Remote {
    public byte[] getModule(java.lang.String moduleVersionID) throws java.rmi.RemoteException;
    public org.openbravo.services.webservice.SimpleModule[] moduleSearch(java.lang.String word, java.lang.String[] exclude) throws java.rmi.RemoteException;
    public org.openbravo.services.webservice.Module moduleDetail(java.lang.String moduleVersionID) throws java.rmi.RemoteException;
    public org.openbravo.services.webservice.SimpleModule[] moduleScanForUpdates(java.util.HashMap moduleIdInstalledModules) throws java.rmi.RemoteException;
    public org.openbravo.services.webservice.Module moduleRegister(org.openbravo.services.webservice.Module module, java.lang.String userName, java.lang.String password) throws java.rmi.RemoteException;
    public org.openbravo.services.webservice.ModuleInstallDetail checkConsistency(java.util.HashMap versionIdInstalled, java.lang.String[] versionIdToInstall, java.lang.String[] versionIdToUpdate) throws java.rmi.RemoteException;
    public java.lang.String getURLforDownload(java.lang.String moduleVersionID) throws java.rmi.RemoteException;
    public boolean isCommercial(java.lang.String moduleVersionID) throws java.rmi.RemoteException;
}
