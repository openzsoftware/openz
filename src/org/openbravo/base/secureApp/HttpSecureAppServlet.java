/*
 ***************************************************************************************************************************************************
* The contents of this file are subject to the Openbravo  Public  License Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
* Version 1.1  with a permitted attribution clause; you may not  use this file except in compliance with the License. You  may  obtain  a copy of
* the License at http://www.openbravo.com/legal/license.html. Software distributed under the License  is  distributed  on  an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the specific  language  governing  rights  and  limitations
* under the License. The Original Code is Openbravo ERP.
* The Initial Developer of the Original Code is Openbravo SL. Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
* All Rights Reserved.
* Contributor(s): Stefan Zimmermann, sz@zimmermann-software.de (SZ) Contributions are Copyright (C) 2011 Stefan Zimmermann
****************************************************************************************************************************************************
 */
package org.openbravo.base.secureApp;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.sql.Connection;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JRParameter;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.design.JRDesignParameter;
import net.sf.jasperreports.engine.design.JasperDesign;

import net.sf.jasperreports.engine.xml.JRXmlLoader;

import org.openbravo.authentication.AuthenticationException;
import org.openbravo.authentication.AuthenticationManager;
import org.openbravo.authentication.basic.DefaultAuthenticationManager;
import org.openbravo.base.HttpBaseServlet;
import org.openbravo.base.exception.OBException;
import org.openbravo.dal.core.OBContext;
import org.openbravo.dal.service.OBDal;
import org.openbravo.data.FieldProvider;

import org.openbravo.erpCommon.security.SessionLogin;
import org.openbravo.erpCommon.security.SessionLoginData;
import org.openbravo.erpCommon.utility.JRFieldProviderDataSource;
import org.openbravo.erpCommon.utility.JRFormatFactory;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.PrintJRData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.model.ad.system.SystemInformation;
import org.openbravo.scheduling.OBScheduler;
import org.openbravo.scheduling.ProcessBundle;
import org.openbravo.scheduling.ProcessBundle.Channel;
import org.openbravo.scheduling.ProcessRequestData;
import org.openbravo.utils.CryptoSHA1BASE64;
import org.openbravo.utils.FileUtility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.LocalizationUtils;
import org.openz.util.UtilsData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureButton;
import org.openz.view.templates.ConfigureContentPage;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public class HttpSecureAppServlet extends HttpBaseServlet {
  private static final long serialVersionUID = 1L;
  protected boolean boolHist = true;
  // String myTheme = "";
  protected ClassInfoData classInfo;
  private AuthenticationManager m_AuthManager = null;

  private String servletClass = this.getClass().getName();
  private String windowId="";
  private String tabId="";
  private String updatedtimestamp="";
  private String orgparent="";
  private String commandtype="";
  private String createdFile="";
  
  
  private class Variables extends VariablesHistory {
    public Variables(HttpServletRequest request) {
      super(request);
    }
    // SZ Do not historize the Image servlet.
    public void updateHistory(HttpServletRequest request) {
      if (boolHist) {
        String sufix = getCurrentHistoryIndex();
        if (!(servletClass.equals(getSessionValue("reqHistory.servlet" + sufix, "")))
            && !(servletClass.equals("org.openbravo.erpCommon.utility.ShowImage"))
            && !(servletClass.equals("org.openbravo.erpWindows.Element.Translation"))) {
          upCurrentHistoryIndex();
          sufix = getCurrentHistoryIndex();
          setSessionValue("reqHistory.servlet" + sufix, servletClass);
          setSessionValue("reqHistory.path" + sufix, request.getServletPath());
          setSessionValue("reqHistory.command" + sufix, "DEFAULT");
        }
      }
    }

    public void setHistoryCommand(String strCommand) {
      final String sufix = getCurrentHistoryIndex();
      setSessionValue("reqHistory.command" + sufix, strCommand);
    }
  }

  @Override
  public void init(ServletConfig config) {
    super.init(config);

    // Authentication manager load
    // String sAuthManagerClass =
    // config.getServletContext().getInitParameter("AuthenticationManager");
    String sAuthManagerClass = globalParameters.getOBProperty("authentication.class");
    if (sAuthManagerClass == null || sAuthManagerClass.equals("")) {
      // If not defined, load default
      sAuthManagerClass = "org.openbravo.authentication.basic.DefaultAuthenticationManager";
    }

    try {
      m_AuthManager = (AuthenticationManager) Class.forName(sAuthManagerClass).getConstructor().newInstance();
    } catch (final Exception e) {
      log4j.error("Authentication manager not defined", e);
      m_AuthManager = new DefaultAuthenticationManager();
    }

    try {
      m_AuthManager.init(this);
    } catch (final AuthenticationException e) {
      log4j.error("Unable to initialize authentication manager", e);
    }

    if (log4j.isDebugEnabled())
      log4j.debug("strdireccion: " + strDireccion);

    // Calculate class info
    try {
      if (log4j.isDebugEnabled())
        log4j.debug("Servlet request for class info: " + this.getClass());
      ClassInfoData[] classInfoAux = ClassInfoData.select(this, this.getClass().getName());
      if (classInfoAux != null && classInfoAux.length > 0)
        classInfo = classInfoAux[0];
      else {
        classInfoAux = ClassInfoData.set();
        classInfo = classInfoAux[0];
      }
    } catch (final Exception ex) {
      log4j.error(ex);
      ClassInfoData[] classInfoAux;
      try {
        classInfoAux = ClassInfoData.set();
        classInfo = classInfoAux[0];
      } catch (ServletException e) {
        log4j.error(e);
      }
    }
  }

  @Override
  public void service(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
    Variables variables = new Variables(request);
    // VariablesSecureApp vars = new VariablesSecureApp(request);

    // bdErrorGeneral(response, "Error", "No access");

    if (log4j.isDebugEnabled())
      log4j.debug("class info type: " + classInfo.type + " - ID: " + classInfo.id);
    String strAjax = "";
    String strHidden = "";
    String strPopUp = "";
    try {
      strAjax = request.getParameter("IsAjaxCall");
    } catch (final Exception ignored) {
    }
    try {
      strHidden = request.getParameter("IsHiddenCall");
    } catch (final Exception ignored) {
    }
    try {
      strPopUp = request.getParameter("IsPopUpCall");
    } catch (final Exception ignored) {
    }

    try {

      OBContext.enableAsAdminContext();

      final String strUserAuth = m_AuthManager.authenticate(request, response);
      variables = new Variables(request); // Rebuild variable, auth-mgr could set the role

      boolean loggedOK = false;

      if (!variables.getDBSession().equals("")) {
        String test=variables.getDBSession();
        loggedOK = SeguridadData.loggedOK(this, variables.getDBSession());
        if (!loggedOK) {
          logout(request, response);
          return;
        }
      }

      if (strUserAuth != null) {
        if (!loggedOK) {
          String strLanguage = "";
          String strIsRTL = "";
          String strRole = "";
          String strClient = "";
          String strOrg = "";
          String strWarehouse = "";

          SystemInformation sysInfo = OBDal.getInstance().get(SystemInformation.class, "0");
          boolean correctSystemStatus = sysInfo.getSystemStatus() == null
              || this.globalParameters.getOBProperty("safe.mode", "false")
                  .equalsIgnoreCase("false") || sysInfo.getSystemStatus().equals("RB70");
          //ActivationKey ak = new ActivationKey();
          //LicenseRestriction limitation = ak.checkOPSLimitations(variables.getDBSession());
          // We check if there is a Openbravo Professional Subscription restriction in the license,
          // or if the last rebuild didn't go well. If any of these are true, then the user is
          // allowed to login only as system administrator
         //if( limitation == LicenseRestriction.OPS_INSTANCE_NOT_ACTIVE
         // || limitation == LicenseRestriction.NUMBER_OF_CONCURRENT_USERS_REACHED
          //|| limitation == LicenseRestriction.MODULE_EXPIRED ||!correctSystemStatus)
          if ( !correctSystemStatus) {
            // it is only allowed to log as system administrator
            strRole = DefaultOptionsData.getDefaultSystemRole(this, strUserAuth);
            if (strRole == null || strRole.equals("")) {
              final OBError roleError = new OBError();
              roleError.setType("Error");
              roleError.setMessage(Utility.messageBD(this, "SystemLoginRequired", variables
                  .getLanguage()));
              invalidLogin(request, response, roleError);

              return;
            }
            strClient = "0";
            strOrg = "0";
            strWarehouse = "";
          } else {
            strRole = variables.getRole();

            if (strRole.equals("")) {
              strRole = DefaultOptionsData.defaultRole(this, strUserAuth);
              if (strRole == null)
                strRole = DefaultOptionsData.getDefaultRole(this, strUserAuth);
            }
            validateDefault(strRole, strUserAuth, "Role");

            strOrg = DefaultOptionsData.defaultOrg(this, strUserAuth);
            if (strOrg == null)
              strOrg = DefaultOptionsData.getDefaultOrg(this, strRole);
            validateDefault(strOrg, strRole, "Org");

            strClient = DefaultOptionsData.defaultClient(this, strUserAuth);
            if (strClient == null)
              strClient = DefaultOptionsData.getDefaultClient(this, strRole);
            validateDefault(strClient, strRole, "Client");

            strWarehouse = DefaultOptionsData.defaultWarehouse(this, strUserAuth);
            if (strWarehouse == null) {
              if (!strRole.equals("0")) {
                strWarehouse = DefaultOptionsData.getDefaultWarehouse(this, strClient, new OrgTree(
                    this, strClient).getAccessibleTree(this, strRole).toString());
              } else
                strWarehouse = "";
            }
          }

          DefaultOptionsData dataLanguage[] = DefaultOptionsData.defaultLanguage(this, strUserAuth);
          if (dataLanguage != null && dataLanguage.length > 0) {
            strLanguage = dataLanguage[0].getField("DEFAULT_AD_LANGUAGE");
            strIsRTL = dataLanguage[0].getField("ISRTL");
          }
          if (strLanguage == null || strLanguage.equals("")) {
            dataLanguage = DefaultOptionsData.getDefaultLanguage(this);
            if (dataLanguage != null && dataLanguage.length > 0) {
              strLanguage = dataLanguage[0].getField("AD_LANGUAGE");
              strIsRTL = dataLanguage[0].getField("ISRTL");
            }
          }
          String strTrlLanguage=strLanguage;
          if (DefaultSessionValuesData.sisonlyformat(this, strLanguage).equals("Y"))
        	  strTrlLanguage=DefaultSessionValuesData.selectdtranslationlanguage(this,strLanguage);
          if (strTrlLanguage==null || strTrlLanguage.isEmpty())
         	 strTrlLanguage=strLanguage;
          final VariablesSecureApp vars = new VariablesSecureApp(request);
          if (LoginUtils.fillSessionArguments(this, vars, strUserAuth, strTrlLanguage, strIsRTL,
              strRole, strClient, strOrg, strWarehouse)) {
        	String x = (String) request.getSession(false).getAttribute("#ScreenX");
        	String y = (String) request.getSession(false).getAttribute("#ScreenY");
        	vars.setSessionValue("#ScreenX", x);
        	vars.setSessionValue("#ScreenY", y);
            readProperties(vars, globalParameters.getOpenbravoPropertiesPath());
            readNumberFormat(vars, globalParameters.getFormatPath(),strLanguage);
            readDateFormat(vars,strLanguage);
            saveLoginBD(request, vars, "0", "0");
            if (DefaultOptionsData.isFirstTimeUse(this).equals("Y")) {
            	DefaultOptionsData.ActivateOSS(this);
            	contentPage(response,"FirsTimeUse",request);
            	return;
            }
            if (DefaultOptionsData.getAnonymInstanceKey(this).isEmpty()) {
            	DefaultOptionsData.setAnonymInstanceKey(this, UtilsData.getUUID(this));
            }
            if (DefaultOptionsData.isStatisticsTime(this).equals("Y")) {
            	//Send Statistics..
            	String requestId;
            	final VariablesSecureApp vars1 = new VariablesSecureApp(request, false);
            	requestId=ProcessRequestData.shduleJobDirectly(this, "StatisticsBG", "4", "1", "I");
            	final ProcessBundle bundle = ProcessBundle.request(requestId, vars1, this);
                OBScheduler.getInstance().schedule(requestId, bundle);
            	//Renew Key.
                requestId=ProcessRequestData.shduleJobDirectly(this, "getSubscriptionBG", "4", "1", "I");
            	final ProcessBundle bundle2 = ProcessBundle.request(requestId, vars1, this);
                OBScheduler.getInstance().schedule(requestId, bundle2);
            	DefaultOptionsData.updateStatistics(this);
            }
            String digest=CryptoSHA1BASE64.hash(DefaultOptionsData.getMainOrg(this));
            int numof;
            if (DefaultOptionsData.getActivationKey(this).equals(digest)) {
            	numof=Integer.parseInt(DefaultOptionsData.getActivationKey2(this));
            } else {
            	DefaultOptionsData.ActivateOSS(this);
            	DefaultOptionsData.setOSS(this);
            	DefaultOptionsData.DisableNonOSS(this);
            	numof=2;
            }
            if (Integer.parseInt(DefaultOptionsData.getsequenceOfLoggedInUser(this, strUserAuth))>numof) {
            	contentPage(response,"ToomanyUsers",request);
            	logout(request, response);
            	return;
            }
            if (SessionLoginData.isAlreadyLoggedIn(this, strUserAuth).equals("Y")) {
            	contentPage(response,"AlreadyLoggedIn",request);
            	vars.setSessionValue("ISLOGGEDIN", "Y");
            	return;
            }
            
          } else {
            // Re-login
            log4j.error("Unable to fill session Arguments for: " + strUserAuth);
            logout(request, response);
            return;
          }
        } else {
          variables.updateHistory(request);
        }
      }
      if (log4j.isDebugEnabled()) {
        log4j.debug("Call to HttpBaseServlet.service");
      }
    } catch (final DefaultValidationException d) {
      // Added DefaultValidationException class to catch user login
      // without a valid role
      final OBError roleError = new OBError();
      roleError.setTitle("Invalid " + d.getDefaultField());
      roleError.setType("Error");
      roleError.setMessage("No valid " + d.getDefaultField()
          + " identified. Please contact your system administrator for access.");
      invalidLogin(request, response, roleError);

      return;
    } catch (final Exception e) {
      // Re-login
      log4j.error("HTTPSecureAppServlet.service() - exception caught: ", e);
      logout(request, response);
      return;
    } finally {
      OBContext.resetAsAdminContext();
    }

    try {

      super.initialize(request, response);
      final VariablesSecureApp vars1 = new VariablesSecureApp(request, false);
      if (vars1.getRole().equals("") || hasAccess(vars1)) {
        // Autosave logic
        final Boolean saveRequest = (Boolean) request.getAttribute("autosave");
        final String strTabId = vars1.getStringParameter("inpTabId");

        if (saveRequest == null && strTabId != null) {

          final String autoSave = request.getParameter("autosave");
         // Boolean failedAutosave = (Boolean) vars1.getSessionObject(strTabId + "|failedAutosave");

          //if (failedAutosave == null) {
          //  failedAutosave = false;
         // }

         // if (autoSave != null && autoSave.equalsIgnoreCase("Y") && !failedAutosave) {
         if (autoSave != null && autoSave.equalsIgnoreCase("Y")) {

            if (log4j.isDebugEnabled()) {
              log4j.debug("service: saveRequest - " + this.getClass().getCanonicalName()
                  + " - autosave: " + autoSave);
            }

            if (log4j.isDebugEnabled()) {
              log4j.debug(this.getClass().getCanonicalName() + " - hash: "
                  + vars1.getPostDataHash());
            }

            final String servletMappingName = request.getParameter("mappingName");

            if (servletMappingName != null
                && !Utility.isExcludedFromAutoSave(this.getClass().getCanonicalName())
                && !vars1.commandIn("DIRECT")) {

              final String hash = vars1.getSessionValue(servletMappingName + "|hash");

              if (log4j.isDebugEnabled()) {
                log4j.debug("hash in session: " + hash);
              }
              // Check if the form was previously saved based on
              // the hash of the post data
              if (!hash.equals(vars1.getPostDataHash())) {
                request.setAttribute("autosave", true);
                if (vars1.getCommand().indexOf("BUTTON") != -1)
                  request.setAttribute("popupWindow", true);
                // forward request
                if (!forwardRequest(request, response)) {
                  return; // failed save
                }
              }
            }
          }
        }
        super.serviceInitialized(request, response);
      } else {
        if ((strPopUp != null && !strPopUp.equals("")) || (classInfo.type.equals("S")))
          bdErrorGeneralPopUp(request, response, Utility.messageBD(this, "Error", variables
              .getLanguage()), Utility
              .messageBD(this, "AccessTableNoView", variables.getLanguage()));
        else
          bdError(request, response, "AccessTableNoView", vars1.getLanguage());
      }
    } catch (final ServletException ex) {
      log4j.error("Error captured: ", ex);
      final VariablesSecureApp vars1 = new VariablesSecureApp(request, false);
      final OBError myError = Utility.translateError(this, vars1, variables.getLanguage(), ex
          .getMessage());
      if (strAjax != null && !strAjax.equals(""))
        bdErrorAjax(response, myError.getType(), myError.getTitle(), myError.getMessage());
      else if (strHidden != null && !strHidden.equals(""))
        bdErrorHidden(response, myError.getType(), myError.getTitle(), myError.getMessage());
      else if (!myError.isConnectionAvailable())
        bdErrorConnection(response);
      else if (strPopUp != null && !strPopUp.equals(""))
        bdErrorGeneralPopUp(request, response, myError.getTitle(), myError.getMessage());
      else
        bdErrorGeneral(request, response, myError.getTitle(), myError.getMessage());
    } catch (final OBException e) {
      final Boolean isAutosaving = (Boolean) request.getAttribute("autosave");
      if (isAutosaving != null && isAutosaving) {
        request.removeAttribute("autosave");
        request.removeAttribute("popupWindow");
        throw e;
      } else {
        log4j.error("Error captured: ", e);
        if (strPopUp != null && !strPopUp.equals(""))
          bdErrorGeneralPopUp(request, response, "Error", e.toString());
        else
          bdErrorGeneral(request, response, "Error", e.toString());
      }
    } catch (final Exception e) {
      log4j.error("Error captured: ", e);
      if (strPopUp != null && !strPopUp.equals(""))
        bdErrorGeneralPopUp(request, response, "Error", e.toString());
      else {
    	e.printStackTrace();
        bdErrorGeneral(request, response, "Error", e.toString());
      }
    }
  }

  /**
   * Cheks access passing all the parameters
   * 
   * @param vars
   * @param type
   *          type of element
   * @param id
   *          id for the element
   * @return true in case it has access false if not
   */
  protected boolean hasGeneralAccess(VariablesSecureApp vars, String type, String id) {
    try {
      final String accessLevel = SeguridadData.selectAccessLevel(this, type, id);
      vars.setSessionValue("#CurrentAccessLevel", accessLevel);
      if (type.equals("W")) {
        return hasLevelAccess(vars, accessLevel)
            && SeguridadData.selectAccess(this, vars.getRole(), "TABLE", id).equals("0")
            && !SeguridadData.selectAccess(this, vars.getRole(), type, id).equals("0");
      } else if (type.equals("S")) {
        return !SeguridadData.selectAccessSearch(this, vars.getRole(), id).equals("0");
      } else if (type.equals("C"))
        return true;
      else
        return hasLevelAccess(vars, accessLevel)
            && !SeguridadData.selectAccess(this, vars.getRole(), type, id).equals("0");
    } catch (final Exception e) {
      log4j.error("Error checking access: ", e);
      return false;
    }

  }

  /**
   * Checks if the user has access to the window
   * */
  private boolean hasAccess(VariablesSecureApp vars) {
    try {
      // Catch Read Only and Visible Settings in Tabs
      
      if (SeguridadData.hasRoleTabAccessReadonly(this, vars.getRole(), tabId) && 
          (vars.getCommand().equals("NEW") || vars.getCommand().equals("DELETE") || vars.getCommand().indexOf("SAVE")>0))
         return false;
      // Location Selector is always allowed to use 
     if (classInfo == null || classInfo.id.equals("") || classInfo.type.equals("")||this.getClass().getName().equals("org.openbravo.erpCommon.info.Location"))
        return true;
      return hasGeneralAccess(vars, classInfo.type, classInfo.id);

    } catch (final Exception e) {
      log4j.error("Error checking access: ", e);
      return false;
    }
  }

  /**
   * Checks if the level access is correct.
   * 
   */
  private boolean hasLevelAccess(VariablesSecureApp vars, String accessLevel) {
    final String userLevel = vars.getSessionValue("#User_Level");

    boolean retValue = true;

    // NOTE: if the logic here changes then also the logic in the
    // EntityAccessChecker.hasCorrectAccessLevel needs to be updated
    // Centralizing the logic seemed difficult because of build dependencies
    if (accessLevel.equals("4") && userLevel.indexOf("S") == -1)
      retValue = false;
    else if (accessLevel.equals("1") && userLevel.indexOf("O") == -1)
      retValue = false;
    else if (accessLevel.equals("3")
        && (!(userLevel.indexOf("C") != -1 || userLevel.indexOf("O") != -1)))
      retValue = false;
    else if (accessLevel.equals("6")
        && (!(userLevel.indexOf("S") != -1 || userLevel.indexOf("C") != -1)))
      retValue = false;

    return retValue;
  }

  /**
   * Validates if a selected default value is null or empty String
   * 
   * @param strValue
   * @param strKey
   * @param strError
   * @throws Exeption
   * */
  private void validateDefault(String strValue, String strKey, String strError) throws Exception {
    if (strValue == null || strValue.equals(""))
      throw new DefaultValidationException("Unable to read default " + strError + " for:" + strKey,
          strError);
  }

  protected void logout(HttpServletRequest request, HttpServletResponse response)
      throws IOException, ServletException {

    HttpSession session = request.getSession(false);
    if (session != null) {
      // finally invalidate the session (this event will be caught by the session listener
      session.invalidate();
    }
    OBContext.setOBContext((OBContext) null);
    m_AuthManager.logout(request, response);
  }

  /**
   * Logs the user out of the application, clears the session and returns the HTMLErrorLogin page
   * with the relevant error message passed into the method.
   * 
   * @param request
   * @param response
   * @param error
   * @throws IOException
   * @throws ServletException
   */
  private void invalidLogin(HttpServletRequest request, HttpServletResponse response, OBError error)
      throws IOException, ServletException {

    HttpSession session = request.getSession(false);
    if (session != null) {
      // finally invalidate the session (this event will be caught by the session listener
      session.invalidate();
    }
    OBContext.setOBContext((OBContext) null);

    String discard[] = { "continueButton" };

    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/HtmlErrorLogin", discard).createXmlDocument();

    xmlDocument.setParameter("messageType", error.getType());
    xmlDocument.setParameter("messageTitle", error.getTitle());
    xmlDocument.setParameter("messageMessage", error.getMessage());

    response.setContentType("text/html");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();

  }

  protected void setHistoryCommand(HttpServletRequest request, String strCommand) {
    final Variables vars = new Variables(request);
    vars.setHistoryCommand(strCommand);
  }

 

  protected void advise(HttpServletRequest request, HttpServletResponse response, String strTipo,
      String strTitulo, String strTexto) throws IOException {

    String myTheme;
    if (request != null)
      myTheme = new Variables(request).getSessionValue("#Theme");
    else
      myTheme = "Default";

    final XmlDocument xmlDocument = xmlEngine
        .readXmlTemplate("org/openbravo/base/secureApp/Advise").createXmlDocument();

    xmlDocument.setParameter("theme", myTheme);
    xmlDocument.setParameter("ParamTipo", strTipo.toUpperCase());
    xmlDocument.setParameter("ParamTitulo", strTitulo);
    xmlDocument.setParameter("ParamTexto", strTexto);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void advisePopUp(HttpServletRequest request, HttpServletResponse response,
      String strTitulo, String strTexto) throws IOException {
    advisePopUp(request, response, "Error", strTitulo, strTexto);
  }

  protected void advisePopUp(HttpServletRequest request, HttpServletResponse response,
      String strTipo, String strTitulo, String strTexto) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/AdvisePopUp").createXmlDocument();

    String myTheme;
    if (request != null)
      myTheme = new Variables(request).getSessionValue("#Theme");
    else
      myTheme = "Default";
    xmlDocument.setParameter("theme", myTheme);
    xmlDocument.setParameter("ParamTipo", strTipo.toUpperCase());
    xmlDocument.setParameter("ParamTitulo", strTitulo);
    xmlDocument.setParameter("ParamTexto", strTexto);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  /**
   * Creates a pop up that when closed, will refresh the parent window.
   * 
   * @param response
   *          the HttpServletResponse object
   * @param strTitle
   *          the title of the popup window
   * @param strText
   *          the text to be displayed in the popup message area
   * @throws IOException
   *           if an error occurs writing to the output stream
   */
  

 

  
  /**
   * Creates a pop up that when closed, will refresh the parent window.
   * 
   * @param response
   *          the HttpServletResponse object
   * @param strType
   *          the type of message to be displayed (e.g. ERROR, SUCCESS)
   * @param strTitle
   *          the title of the popup window
   * @param strText
   *          the text to be displayed in the popup message area
   * @throws IOException
   *           if an error occurs writing to the output stream
   */
  protected void advisePopUpRefresh(HttpServletRequest request, HttpServletResponse response,
      String strType, String strTitle, String strText) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/AdvisePopUpRefresh").createXmlDocument();

    String myTheme;
    if (request != null)
      myTheme = new Variables(request).getSessionValue("#Theme");
    else
      myTheme = "Default";

    xmlDocument.setParameter("theme", myTheme);
    xmlDocument.setParameter("ParamType", strType.toUpperCase());
    xmlDocument.setParameter("ParamTitle", strTitle);
    xmlDocument.setParameter("ParamText", strText);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  

  protected void bdError(HttpServletRequest request, HttpServletResponse response, String strCode,
      String strLanguage) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/base/secureApp/Error")
        .createXmlDocument();

    String myTheme;
    if (request != null)
      myTheme = new Variables(request).getSessionValue("#Theme");
    else
      myTheme = "Default";

    xmlDocument.setParameter("theme", myTheme);
    xmlDocument.setParameter("ParamTitulo", strCode);
    xmlDocument.setParameter("ParamTexto", Utility.messageBD(this, strCode, strLanguage));
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  

  protected void bdErrorGeneralPopUp(HttpServletRequest request, HttpServletResponse response,
      String strTitle, String strText) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/ErrorPopUp").createXmlDocument();

    String myTheme;
    if (request != null)
      myTheme = new Variables(request).getSessionValue("#Theme");
    else
      myTheme = "Default";

    xmlDocument.setParameter("theme", myTheme);
    xmlDocument.setParameter("ParamTipo", "ERROR");
    xmlDocument.setParameter("ParamTitulo", strTitle);
    xmlDocument.setParameter("ParamTexto", strText);
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

 

  private void bdErrorGeneral(HttpServletRequest request, HttpServletResponse response,
      String strTitle, String strText) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate("org/openbravo/base/secureApp/Error")
        .createXmlDocument();

    String myTheme;
    if (request != null)
      myTheme = new Variables(request).getSessionValue("#Theme");
    else
      myTheme = "Default";

    xmlDocument.setParameter("theme", myTheme);
    xmlDocument.setParameter("ParamTitulo", strTitle);
    xmlDocument.setParameter("ParamTexto", strText);

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void bdErrorConnection(HttpServletResponse response) throws IOException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Error connection");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/ErrorConnection").createXmlDocument();

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void bdErrorAjax(HttpServletResponse response, String strType, String strTitle,
      String strText) throws IOException {
    response.setContentType("text/xml; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
    out.println("<xml-structure>\n");
    out.println("  <status>\n");
    out.println("    <type>" + strType + "</type>\n");
    out.println("    <title>" + strTitle + "</title>\n");
    out.println("    <description><![CDATA[" + strText + "]]></description>\n");
    out.println("  </status>\n");
    out.println("</xml-structure>\n");
    out.close();
  }

  protected void bdErrorHidden(HttpServletResponse response, String strType, String strTitle,
      String strText) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/ad_callouts/CallOut").createXmlDocument();

    final StringBuffer resultado = new StringBuffer();
    resultado.append("var calloutName='';\n\n");
    resultado.append("var respuesta = new Array(\n");

    resultado.append("new Array(\"MESSAGE\", \"");
    resultado.append(strText);
    resultado.append("\")");
    resultado.append("\n);");

    xmlDocument.setParameter("array", resultado.toString());
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void pageError(HttpServletResponse response) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/HtmlError").createXmlDocument();

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void pageErrorPopUp(HttpServletResponse response) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/HtmlErrorPopUp").createXmlDocument();

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void contentPage(HttpServletResponse response,String content,HttpServletRequest request) throws IOException {
	  String html; 
	  StringBuilder btn1;
	  StringBuilder btn2;
	  String cont="";
	  String msgText;
	  Scripthelper script=new Scripthelper();
	  final VariablesSecureApp vars = new VariablesSecureApp(request, false);
	  try {
		if (content.equals("FirsTimeUse")) {
			msgText=LocalizationUtils.getMessageText(this, "OZFirstTimeUse", vars.getLanguage());
		    html=	"<TABLE><tr>"+ msgText + "</tr><tr>";
		    //Sie benutzen OpenZ zum ersten mal.<br/> Akzeptieren Sie die Bedingungen ?

		    btn1=ConfigureButton.doConfigureNew(this, vars, script, "Akzeptieren", 0, 2, false, "", "submitCommandForm('FIRSTTIMECREATEORG', true, null, '../security/Menu.html', '_self', null, true);return false;", "","","","_LI");
		    btn2=ConfigureButton.doConfigureNew(this, vars, script, "Ablehnen", 0, 2, false, "", "submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;", "","","","_LI");
		    
		    //LocalizationUtils.getMessageText(this, "FirsTimeUse", "en_US");
		    cont=ConfigureContentPage.doConfigureContentPage(this, vars, "FirstTime OpenZ", html+ "</tr></TABLE>"+"<div class=\"centri\">"+btn1.toString()+btn2.toString()+"</div>");
	    }
		else if (content.equals("ToomanyUsers")) {
			msgText=LocalizationUtils.getMessageText(this, "OZLicenseInvalid", vars.getLanguage());
			html=	"<TABLE><tr>" + msgText + "</tr><tr>";
		    //Die Nazahl der lizensierten Nuter ist überschritten<br/> Akzeptieren Sie die Bedingungen ...

		    
		    btn2=ConfigureButton.doConfigureNew(this, vars, script, "OK", 0, 2, false, "", "submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;", "","","","_LI");
		    
		    //LocalizationUtils.getMessageText(this, "FirsTimeUse", "en_US");
		    cont=ConfigureContentPage.doConfigureContentPage(this, vars, "OpenZ TooMany Users", html +"</tr></TABLE>"+"<div class=\"centri\">"+btn2.toString()+"</div>");
	    }
		else if (content.equals("AlreadyLoggedIn")) {
			msgText=LocalizationUtils.getMessageText(this, "OZAlreadyLoggedIn", vars.getLanguage());
			html=	"<TABLE><tr>" + msgText + "</tr><tr>";
		    
		    btn1=ConfigureButton.doConfigureNew(this, vars, script, "logloutothersession", 0, 2, false, "", "submitCommandForm('DEACTIVATEOTHER', true, null, '../security/Menu.html', '_self', null, true);return false;", "","","","_LI");
		    btn2=ConfigureButton.doConfigureNew(this, vars, script, "Ausloggen", 0, 2, false, "", "submitCommandForm('DEFAULT', false, null, '../security/Logout.html', '_top');return false;", "","","","_LI");
		    
		    //LocalizationUtils.getMessageText(this, "FirsTimeUse", "en_US");
		    cont=ConfigureContentPage.doConfigureContentPage(this, vars, "Already LoggedIn", html + "</tr></TABLE>"+"<div class=\"centri\">"+btn1.toString()+btn2.toString()+"</div>" );
	    } else {
	    	btn1=ConfigureButton.doConfigureNew(this, vars, script, "OK", 0, 2, false, "", "submitCommandForm('DEFAULT', true, null, '../security/Menu.html', '_self', null, true);return false;", "","","","_LI");
	    	cont=ConfigureContentPage.doConfigureContentPage(this, vars, "Contenttime","<TABLE><tr>" + content  + "</tr></TABLE>"+"<div class=\"centri\">"+btn1.toString()+"</div>");
	    }
	    cont=script.doScript(cont, "",this,vars);
	    cont.replaceAll("calendar-.js", "calendar-de.js");
		response.setContentType("text/html; charset=UTF-8");
	    final PrintWriter out = response.getWriter();
	    out.println(cont);
	    out.close();
	  } catch (final Exception e) {
	      log4j.error("Error ContentPage: ", e);
	    }		
	  }
  
  protected void whitePage(HttpServletResponse response) throws IOException {
    whitePage(response, "");
  }

  protected void whitePage(HttpServletResponse response, String strAlert) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/HtmlWhitePage").createXmlDocument();
    if (strAlert == null)
      strAlert = "";
    xmlDocument.setParameter("body", strAlert);

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void printPageClosePopUp(HttpServletResponse response, VariablesSecureApp vars,
      String path) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: PopUp Response");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/PopUp_Response").createXmlDocument();
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("href", path.equals("") ? "null" : "'" + path + "'");
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void printPageClosePopUp(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {
    printPageClosePopUp(response, vars, "");
  }

 

  protected void printPagePopUpDownload(ServletOutputStream os, String fileName)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: PopUp Download");
    String href = strDireccion + "/utility/DownloadReport.html?report=" + fileName;
    XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/PopUp_Download").createXmlDocument();
    xmlDocument.setParameter("href", href);
    os.println(xmlDocument.print());
    os.close();
  }
  // SZ: New Method: Generic File Download  
  public void printPagePopUpDownloadFile(ServletOutputStream os, String fileName, String fdir)
  throws IOException, ServletException {
        if (log4j.isDebugEnabled())
          log4j.debug("Output: PopUp Download");
        String href = strDireccion + "/utility/DownloadFile.html?dfile=" + fileName + "&fdir=" + fdir;
        XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
            "org/openbravo/base/secureApp/PopUp_Download").createXmlDocument();
        xmlDocument.setParameter("href", href);
        os.println(xmlDocument.print());
        os.close();
   }

  private void printPageClosePopUpAndRefresh(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: PopUp Response");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/PopUp_Close_Refresh").createXmlDocument();
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void printPageClosePopUpAndRefreshParent(HttpServletResponse response,
      VariablesSecureApp vars) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: PopUp Response");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/PopUp_Close_And_Refresh").createXmlDocument();
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void pageErrorCallOut(HttpServletResponse response) throws IOException {
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/base/secureApp/HtmlErrorCallOut").createXmlDocument();

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  protected void readProperties(VariablesSecureApp vars, String strFileProperties) {
    // Read properties file.
    final Properties properties = new Properties();
    try {

      properties.load(new FileInputStream(strFileProperties));
      final String javaDateFormat = properties.getProperty("dateFormat.java");
      vars.setSessionValue("#AD_JavaDateFormat", javaDateFormat);

      final String javaDateTimeFormat = properties.getProperty("dateTimeFormat.java");
      vars.setSessionValue("#AD_JavaDateTimeFormat", javaDateTimeFormat);

      final String sqlDateTimeFormat = properties.getProperty("dateTimeFormat.sql");
      vars.setSessionValue("#AD_SqlDateTimeFormat", sqlDateTimeFormat);

      final String jsDateFormat = properties.getProperty("dateFormat.js");
      vars.setSessionValue("#AD_JsDateFormat", jsDateFormat);

      final String sqlDateFormat = properties.getProperty("dateFormat.sql");
      vars.setSessionValue("#AD_SqlDateFormat", sqlDateFormat);
      vars.setSessionValue("#AD_ReportDateFormat", sqlDateFormat);

      final String pentahoServer = properties.getProperty("pentahoServer");
      vars.setSessionValue("#pentahoServer", pentahoServer);

      final String sourcePath = properties.getProperty("source.path");
      vars.setSessionValue("#sourcePath", sourcePath);

      if (log4j.isDebugEnabled()) {
        log4j.debug("strFileProperties: " + strFileProperties);
        log4j.debug("javaDateFormat: " + javaDateFormat);
        log4j.debug("javaDateTimeFormat: " + javaDateTimeFormat);
        log4j.debug("jsDateFormat: " + jsDateFormat);
        log4j.debug("sqlDateFormat: " + sqlDateFormat);
        log4j.debug("pentahoServer: " + pentahoServer);
        log4j.debug("sourcePath: " + sourcePath);
      }
    } catch (final IOException e) {
      // catch possible io errors from readLine()
      log4j.error("Error reading properties", e);
    }
  }

  protected void readNumberFormat(VariablesSecureApp vars, String strFormatFile, String lang) {
    String strGroupingSeparator = "."; // Default grouping separator
    String strDecimalSeparator = ","; // Default decimal separator
    String pricedec;
    String amtdec;
    String qtydec;
    String strFormatOutput;
    String strReportNumberFormat="###,##0.00"; // Default REPORT number format (DEPRECATED)
    final HashMap<String, String> formatMap = new HashMap<String, String>();
    try {
      if (!DefaultSessionValuesData.selectdecimalseparator(this,lang).isEmpty() && !DefaultSessionValuesData.selectthousandseparator(this, lang).isEmpty()) {
        strDecimalSeparator=DefaultSessionValuesData.selectdecimalseparator(this, lang);
        strGroupingSeparator=DefaultSessionValuesData.selectthousandseparator(this, lang);
      }
      pricedec=DefaultSessionValuesData.getPriceDec(this);
      amtdec=DefaultSessionValuesData.getCurrencyDec(this);
      qtydec=DefaultSessionValuesData.getQtyDec(this);
      // Reading number format configuration
      @SuppressWarnings( "deprecation" )
      final DocumentBuilderFactory docBuilderFactory = DocumentBuilderFactory.newInstance();
      final DocumentBuilder docBuilder = docBuilderFactory.newDocumentBuilder();
      final Document doc = docBuilder.parse(new File(strFormatFile));
      doc.getDocumentElement().normalize();
      final NodeList listOfNumbers = doc.getElementsByTagName("Number");
      final int totalNumbers = listOfNumbers.getLength();
      for (int s = 0; s < totalNumbers; s++) {
        final Node NumberNode = listOfNumbers.item(s);
        if (NumberNode.getNodeType() == Node.ELEMENT_NODE) {
          final Element NumberElement = (Element) NumberNode;
          final String strNumberName = NumberElement.getAttributes().getNamedItem("name").getNodeValue();
          strFormatOutput="";
          if (strNumberName.contains("Relation")||strNumberName.contains("Edition")) {
	          if (strNumberName.startsWith("euro"))
	        	  strFormatOutput = NumberElement.getAttributes().getNamedItem("formatOutput")
	              .getNodeValue().replace(".00", ".")+amtdec;
	          if (strNumberName.startsWith("price"))
	        	  strFormatOutput = NumberElement.getAttributes().getNamedItem("formatOutput")
	              .getNodeValue().replace(".0000", ".")+pricedec;
	          if (strNumberName.startsWith("qty"))
	        	  strFormatOutput = NumberElement.getAttributes().getNamedItem("formatOutput")
	              .getNodeValue().replace(".###",".")+qtydec;
          }
          if (strFormatOutput.isEmpty())
        	  strFormatOutput = NumberElement.getAttributes().getNamedItem("formatOutput")
              .getNodeValue();
         // strFormatOutput=strFormatOutput.replace(",", "@");
         // strFormatOutput=strFormatOutput.replace(".",strDecimalSeparator);
         // strFormatOutput=strFormatOutput.replace("@", strGroupingSeparator);
          formatMap.put(strNumberName, strFormatOutput);
          vars.setSessionValue("#FormatOutput|" + strNumberName, strFormatOutput);
          vars.setSessionValue("#DecimalSeparator|" + strNumberName, strDecimalSeparator);
          vars.setSessionValue("#GroupSeparator|" + strNumberName, strGroupingSeparator);
          
        }
      }
    } catch (final Exception e) {
      log4j.error("error reading number format", e);
    }
    vars.setSessionObject("#FormatMap", formatMap);
    vars.setSessionValue("#AD_ReportNumberFormat", strReportNumberFormat);
    vars.setSessionValue("#AD_ReportGroupingSeparator", strGroupingSeparator);
    vars.setSessionValue("#AD_ReportDecimalSeparator", strDecimalSeparator);
  }

  protected void readDateFormat(VariablesSecureApp vars,String strLanguage){
    try {
      // Implementing International Formats for Numbers and Dates
      if (! DefaultSessionValuesData.selectddateformat(this, strLanguage).isEmpty()) {
        vars.setSessionValue("#AD_JavaDateFormat", DefaultSessionValuesData.selectddateformat(this, strLanguage).replace("DD", "dd").replace("Y", "y"));
        vars.setSessionValue("#AD_JavaDateTimeFormat", DefaultSessionValuesData.selectddateformat(this, strLanguage).replace("DD", "dd").replace("Y", "y") + " HH:mm:ss");
        vars.setSessionValue("#AD_SqlDateFormat",DefaultSessionValuesData.selectddateformat(this, strLanguage));
        vars.setSessionValue("#AD_SqlDateTimeFormat", DefaultSessionValuesData.selectddateformat(this, strLanguage) + " HH24:MI:SS");
        vars.setSessionValue("#AD_ReportDateFormat", DefaultSessionValuesData.selectddateformat(this, strLanguage));
      }  
      if (!DefaultSessionValuesData.selectreportdateformat(this,strLanguage).isEmpty())
    	  vars.setSessionValue("#AD_ReportDateFormat",  DefaultSessionValuesData.selectreportdateformat(this,strLanguage));
      if (DefaultSessionValuesData.selectdtranslationlanguage(this, strLanguage)!=null) {
        vars.setSessionValue("#AD_Language", DefaultSessionValuesData.selectdtranslationlanguage(this, strLanguage));
      }
    } catch (final Exception e) {
      log4j.error("error reading date format", e);
    }
  }
  
  
  private void saveLoginBD(HttpServletRequest request, VariablesSecureApp vars, String strCliente,
      String strOrganizacion) throws ServletException {
    final SessionLogin sl = new SessionLogin(request, strCliente, strOrganizacion, vars
        .getSessionValue("#AD_User_ID"));
    sl.setServerUrl(strDireccion);
    sl.save(this);
    vars.setSessionValue("#AD_Session_ID", sl.getSessionID());
  }

  @SuppressWarnings("deprecation")
  protected void renderJR(VariablesSecureApp variables, HttpServletResponse response,
      String strReportName, String strOutputType, HashMap<String, Object> designParameters,
      FieldProvider[] data, Map<Object, Object> exportParameters) throws ServletException {

    if (strReportName == null || strReportName.equals(""))
      strReportName = PrintJRData.getReportName(this, classInfo.id);

    final String strAttach = globalParameters.strFTPDirectory + "/284-" + classInfo.id;
    String strLanguage = "";
    try {
      strLanguage =(String)designParameters.get("ad_language");
    } catch (final Exception e) {}
    if (strLanguage==null || strLanguage.isEmpty()) 
       strLanguage=variables.getLanguage();
    final Locale locLocale = new Locale(strLanguage.substring(0, 2), strLanguage.substring(3, 5));

    final String strBaseDesign = getBaseDesignPath(strLanguage);

    strReportName = Replace.replace(Replace.replace(strReportName, "@basedesign@", strBaseDesign),
        "@attach@", strAttach);
    // SZ added Options for Sub-Reports (Multi-Language!!)
    // Usage: The same than in ReportManager
    /* SZ
     * TODO: At present this process assumes the subreport is a .jrxml file. Need to handle the
     * possibility that this subreport file could be a .jasper file.
     * Unification of  Subreport-Loading and Report Management
     * Not in This class , Better unify the Report-Manager and use it here
     */
    final String strPathname = strReportName.substring(0, strReportName.lastIndexOf("/") +1);
    String strFileName = strReportName.substring(strReportName.lastIndexOf("/") + 1);
    
    ServletOutputStream os = null;
    UUID reportId = null;
    if (designParameters == null)
      designParameters = new HashMap<String, Object>();
    try {
      
      JasperDesign jasperDesign = JRXmlLoader.load(strReportName);
      Object[] parameters = jasperDesign.getParametersList().toArray();
      String parameterName = "";
      String subReportName = "";
      Collection<String> subreportList = new ArrayList<String>();
      
      for (int i = 0; i < parameters.length; i++) {
        final JRDesignParameter parameter = (JRDesignParameter) parameters[i];
        if (parameter.getName().startsWith("SUBREP_")) {
          parameterName = parameter.getName();
          subreportList.add(parameterName);
          subReportName = Replace.replace(parameterName, "SUBREP_", "") + ".jrxml";
          JasperReport jasperReportLines = createSubReport(strPathname, subReportName,
              strBaseDesign,strLanguage);
          designParameters.put(parameterName, jasperReportLines);
        }
      }
           
      final JasperReport jasperReport = Utility.getTranslatedJasperReport(this, strReportName,
          strLanguage, strBaseDesign);
      

      Boolean pagination = true;
      if (strOutputType.equals("pdf"))
        pagination = false;

      designParameters.put("IS_IGNORE_PAGINATION", pagination);
      designParameters.put("BASE_WEB", strReplaceWithFull);
      designParameters.put("BASE_DESIGN", strBaseDesign);
      designParameters.put("ATTACH", strAttach);
      String strBaseAttach=globalParameters.strFTPDirectory;
      designParameters.put("BASE_ATTACH", strBaseAttach);
      designParameters.put("USER_CLIENT", Utility.getContext(this, variables, "#User_Client", ""));
      designParameters.put("USER_ORG", Utility.getContext(this, variables, "#User_Org", ""));
      designParameters.put("LANGUAGE", strLanguage);
      designParameters.put("LOCALE", locLocale);
      String dateformat=variables.getSessionValue("#AD_ReportDateFormat");
      dateformat=dateformat.replace("DD", "dd");
      designParameters.put("DATEFORMAT",dateformat);
      if (designParameters.get("REPORT_TITLE")!=null)
        if (designParameters.get("REPORT_TITLE").equals(""))
         designParameters.put("REPORT_TITLE", PrintJRData.getReportTitle(this,
          variables.getLanguage(), classInfo.id));

      final DecimalFormatSymbols dfs = new DecimalFormatSymbols();
      dfs.setDecimalSeparator(variables.getSessionValue("#AD_ReportDecimalSeparator").charAt(0));
      dfs.setGroupingSeparator(variables.getSessionValue("#AD_ReportGroupingSeparator").charAt(0));
      final DecimalFormat numberFormat = new DecimalFormat(variables
          .getSessionValue("#AD_ReportNumberFormat"), dfs);
      designParameters.put("NUMBERFORMAT", numberFormat);

      if (log4j.isDebugEnabled())
        log4j.debug("creating the format factory: " + variables.getJavaDateFormat());
      final JRFormatFactory jrFormatFactory = new JRFormatFactory();
      jrFormatFactory.setDatePattern(variables.getJavaDateFormat());
      designParameters.put(JRParameter.REPORT_FORMAT_FACTORY, jrFormatFactory);

      JasperPrint jasperPrint;
      Connection con = null;
      try {
        con = getTransactionConnection();
        // Special Case Initialization for financial Reports
        if (variables.getStringParameter("inpadProcessId").equals("AD57725B5AF94EB3AE2E6C04999A2FBD")) {
          String bwa=variables.getStringParameter("inpbwaheaderid");
          String datefrom=variables.getDateParameter("inpdateFrom",this);
          String dateto=variables.getDateParameter("inpdateTo",this);
          String org=variables.getStringParameter("inpadOrgId");
          PreferencesData.initBWA(con, this, bwa, datefrom, dateto, org);
        }
        if (data != null) {
          designParameters.put("REPORT_CONNECTION", con);
          jasperPrint = JasperFillManager.fillReport(jasperReport, designParameters,
              new JRFieldProviderDataSource(data, variables.getJavaDateFormat()));
        } else {
          jasperPrint = JasperFillManager.fillReport(jasperReport, designParameters, con);
        }
      } catch (final Exception e) {
        throw new ServletException(e.getMessage(), e);
      } finally {
        releaseRollbackConnection(con);
      }

     
      if (exportParameters == null)
        exportParameters = new HashMap<Object, Object>();
      if (strOutputType == null || strOutputType.equals(""))
        strOutputType = "html";
      if (strOutputType.equals("html")) {
        if (log4j.isDebugEnabled())
          log4j.debug("JR: Print HTML");
        response.setHeader("Content-disposition", "inline" + "; filename=" + strFileName + "."
            + strOutputType);
        os = response.getOutputStream();
        final net.sf.jasperreports.engine.export.JRHtmlExporter exporter = new net.sf.jasperreports.engine.export.JRHtmlExporter();
//        exportParameters.put(JRExporterParameter.JASPER_PRINT, jasperPrint);
//        exportParameters.put(JRHtmlExporterParameter.IS_USING_IMAGES_TO_ALIGN, Boolean.FALSE);
//        exportParameters.put(JRHtmlExporterParameter.SIZE_UNIT,
//            JRHtmlExporterParameter.SIZE_UNIT_POINT);
//        exportParameters.put(JRHtmlExporterParameter.OUTPUT_STREAM, os);
         exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.JASPER_PRINT, jasperPrint);
         exporter.setParameter(net.sf.jasperreports.engine.export.JRHtmlExporterParameter.IS_USING_IMAGES_TO_ALIGN, Boolean.FALSE);
         exporter.setParameter(net.sf.jasperreports.engine.export.JRHtmlExporterParameter.SIZE_UNIT,
             net.sf.jasperreports.engine.export.JRHtmlExporterParameter.SIZE_UNIT_POINT);
         exporter.setParameter(net.sf.jasperreports.engine.export.JRHtmlExporterParameter.OUTPUT_STREAM, os);
        //exporter.setParameters(exportParameters);
        exporter.exportReport();
      } else if (strOutputType.equals("pdf") || strOutputType.equalsIgnoreCase("xls")) {
        reportId = UUID.randomUUID();
        saveReport(variables, jasperPrint, exportParameters, strFileName + "-" + (reportId) + "."
            + strOutputType);
        response.setContentType("text/html;charset=UTF-8");
        response.setHeader("Content-disposition", "inline" + "; filename=" + strFileName + "-"
            + (reportId) + ".html");
        printPagePopUpDownload(response.getOutputStream(), strFileName + "-" + (reportId) + "."
            + strOutputType);
      } else if (strOutputType.equals("pdfFILE")) {
    	  reportId = UUID.randomUUID();
    	  saveReport(variables, jasperPrint, exportParameters, strFileName + "-" + (reportId) + "."
    	            + "pdf");
    	  setCreatedFile(strFileName + "-" + (reportId) + ".pdf");
      } else {
        throw new ServletException("Output format no supported");
      }
    } catch (final JRException e) {
      log4j.error("JR: Error: ", e);
      throw new ServletException(e.getMessage(), e);
    } catch (IOException ioe) {
      try {
        FileUtility f = new FileUtility(globalParameters.strFTPDirectory, strFileName + "-"
            + (reportId) + "." + strOutputType, false, true);
        if (f.exists())
          f.deleteFile();
      } catch (IOException ioex) {
        log4j.error("Error trying to delete temporary report file " + strFileName + "-"
            + (reportId) + "." + strOutputType + " : " + ioex.getMessage());
      }
    } catch (final Exception e) {
      throw new ServletException(e.getMessage(), e);
    } finally {
      try {
        os.close();
      } catch (final Exception e) {
      }
    }
  }

  /**
   * Saves the file and request for download. This approach is required to close the loading pop-up
   * window.
   */
  public void renderFO(String strFo, HttpServletRequest request, HttpServletResponse response)
      throws ServletException {
    File baseDir = new File(globalParameters.strFTPDirectory);
    UUID reportId = UUID.randomUUID();

    int slashPos = request.getRequestURI().lastIndexOf("/");
    int dotPos = request.getRequestURI().lastIndexOf(".");

    String fileName = request.getRequestURI().substring(slashPos + 1, dotPos) + "-" + reportId
        + ".pdf";
    File pdffile = new File(baseDir, fileName);
    OutputStream out = null;

    try {
      out = new FileOutputStream(pdffile);
    } catch (Exception e) {
      log4j.error(e.getMessage(), e);
      throw new ServletException(e.getMessage());
    }

    // Generating and saving file
    super.renderFO(strFo, out);

    try {
      printPagePopUpDownload(response.getOutputStream(), fileName);
    } catch (IOException e) {
      try {
        FileUtility f = new FileUtility(globalParameters.strFTPDirectory, fileName, false, true);
        if (f.exists())
          f.deleteFile();
      } catch (IOException ioex) {
        log4j.error("Error trying to delete temporary report file " + fileName + " : "
            + ioex.getMessage());
      }
    }
  }

  /**
   * Saves the report on the attachments folder for future retrieval
   * 
   * @param vars
   *          An instance of VariablesSecureApp that contains the request parameters
   * @param jp
   *          An instance of JasperPrint of the loaded JRXML template
   * @param exportParameters
   *          A Map with all the parameters passed to all reports
   * @param fileName
   *          The file name for the report
   * @throws JRException
   */
  @SuppressWarnings("deprecation")
  private void saveReport(VariablesSecureApp vars, JasperPrint jp,
      Map<Object, Object> exportParameters, String fileName) throws JRException {
    final String outputFile = globalParameters.strFTPDirectory + "/" + fileName;
    final String reportType = fileName.substring(fileName.lastIndexOf(".") + 1);
    if (reportType.equalsIgnoreCase("pdf")) {
      JasperExportManager.exportReportToPdfFile(jp, outputFile);
    } else if (reportType.equalsIgnoreCase("xls")) {
      
      net.sf.jasperreports.engine.export.JExcelApiExporter exporter = new net.sf.jasperreports.engine.export.JExcelApiExporter();
      //exportParameters.put(JRExporterParameter.JASPER_PRINT, jp);
      //exportParameters.put(JRExporterParameter.OUTPUT_FILE_NAME, outputFile);
      //exportParameters.put(JExcelApiExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
      //exportParameters.put(JExcelApiExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);
      //exportParameters.put(JExcelApiExporterParameter.IS_DETECT_CELL_TYPE, true);
      //exporter.setParameters(exportParameters);
      exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.JASPER_PRINT, jp);
      exporter.setParameter(net.sf.jasperreports.engine.JRExporterParameter.OUTPUT_FILE_NAME, outputFile);
      exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_DETECT_CELL_TYPE, Boolean.TRUE);
      exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_ONE_PAGE_PER_SHEET, Boolean.FALSE);
      exporter.setParameter(net.sf.jasperreports.engine.export.JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, Boolean.TRUE);

      exporter.exportReport();
    } else {
      throw new JRException("Report type not supported");
    }

  }

  /**
   * Forwards request to the referrer servlet to perform operations like "auto-save" Note: The
   * referrer servlet should have a hidden input field with mappingName (e.g.
   * /PurchaOrder/Header_Edition.html) to be able to get a RequestDispatcher
   * 
   * @param request
   * @param response
   * @throws IOException
   * @throws ServletException
   */
  private boolean forwardRequest(HttpServletRequest request, HttpServletResponse response)
      throws IOException, ServletException {
    final String forwardTo = request.getParameter("mappingName");
    final String autoSave = request.getParameter("autosave");
    final String commandType = request.getParameter("inpCommandType");
    final Boolean popupWindow = request.getAttribute("popupWindow") != null ? (Boolean) request
        .getAttribute("popupWindow") : false;

    // Forwarding request to save the modified record
    if (autoSave != null && autoSave.equalsIgnoreCase("Y")) {
      if (forwardTo != null && !forwardTo.equals("")) {
        final RequestDispatcher rd = getServletContext().getRequestDispatcher(forwardTo);
        if (rd != null) {
          final long time = System.currentTimeMillis();
          try {
            if (log4j.isDebugEnabled())
              log4j.debug("forward request to: " + forwardTo);
            rd.include(request, response);
            if (log4j.isDebugEnabled())
              log4j.debug("Request forward took: "
                  + String.valueOf(System.currentTimeMillis() - time) + " ms");
          } catch (final OBException e) {

            request.removeAttribute("autosave");
            request.removeAttribute("popupWindow");

            final VariablesSecureApp vars = new VariablesSecureApp(request);
            final String strTabId = vars.getStringParameter("inpTabId");
            if (!vars.getSessionValue(strTabId + "|concurrentSave").equals("true")) {
              vars.setSessionObject(strTabId + "|failedAutosave", true);
            }

            if (!popupWindow) {
              vars.setSessionValue(strTabId + "|requestURL", strDireccion + request.getServletPath());
              response.sendRedirect(strDireccion + forwardTo + "?Command="
                  + (commandType != null ? commandType : "NEW"));
            } else { // close pop-up
              printPageClosePopUpAndRefresh(response, vars);
            }
            return false;
          }
        }
      }
    }
    request.removeAttribute("autosave");
    request.removeAttribute("popupWindow");
    return true;
  }
  private JasperReport createSubReport(String templateLocation, String subReportFileName,
      String baseDesignPath,String strLanguage) {
    JasperReport jasperReportLines = null;
    try {
      jasperReportLines = Utility.getTranslatedJasperReport(this, templateLocation
          + subReportFileName, strLanguage, baseDesignPath);
    } catch (final JRException e1) {
      log4j.error(e1.getMessage());
      e1.printStackTrace();
    }
    return jasperReportLines;
  }
  public String getWindowId() {
    return windowId;
  }
  public void setWindowId(String windoID) {
    windowId=windoID;
  }
  public String getTabId() {
    return tabId;
  }
  public void setTabId(String tabID) {
    tabId=tabID;
  }
  public String getUpdatedtimestamp() {
    return updatedtimestamp;
  }
  public void setUpdatedtimestamp(String updatedtimestamP) {
    updatedtimestamp=updatedtimestamP;
  }
 
  public String getOrgparent() {
    return orgparent;
  }
  public void setOrgparent(String orgparenT) {
    orgparent=orgparenT;
  }
  public String getCreatedFile() {
	 return createdFile;
  }
  public void setCreatedFile(String _createdFile) {
	  createdFile=_createdFile;
  }
  public String getCommandtype() {
    return commandtype;
  }
  public void setCommandtype(String commandType) {
    commandtype=commandType;
  }
  /**
   * Reads Input Field and writes Value to Session VAR
   * Local means session Var is adessed by Class anme
   * @param ADName - Name of Field and SessionVar (Field is expanded with inp in teh function
   */
  public void setLocalSessionVariable(VariablesSecureApp vars, String ADName) {
    vars.setSessionValue(getServletInfo() + "|" + ADName, vars.getStringParameter("inp" + ADName));
  }
  /**
   * Writes given Value to Session VAR
   * Local means session Var is adessed by Class anme
   * @param ADName - Name of SessionVar 
   * @param Value - Value of SessionVar 
   */
  public void setLocalSessionVariable(VariablesSecureApp vars, String ADName, String Value) {
    vars.setSessionValue(getServletInfo() + "|" + ADName, Value);
  }
  /**
   * Reads Value from Session VAR
   * Local means session Var is adessed by Class anme
   * @param ADName - Name of SessionVar 
   */
  public String getLocalSessionVariable(VariablesSecureApp vars, String ADName) {
    return vars.getSessionValue(getServletInfo() + "|" + ADName);
  }
  /**
   * Deletes Value of Session VAR
   * Local means session Var is adessed by Class anme
   * @param ADName - Name of SessionVar 
   */
  public void deleteLocalSessionVariable(VariablesSecureApp vars, String ADName) {
    vars.removeSessionValue(getServletInfo() + "|" + ADName);
  }
  
  @Override
  public String getServletInfo() {
    return "This servlet add some functions (autentication, privileges, application menu, ...) over HttpBaseServlet";
  }
}
