/*
 * Copyright 2006 Sun Microsystems, Inc. All Rights Reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *  - Redistributions in binary form muskeytool -list -v | moret reproduce the
 * above copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the distribution.
 *  - Neither the name of Sun Microsystems nor the names of its contributors may
 * be used to endorse or promote products derived from this software without
 * specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package org.openbravo.erpCommon.utility;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;
import java.net.UnknownHostException;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLException;
import javax.net.ssl.SSLHandshakeException;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

import org.apache.log4j.Logger;

public class HttpsUtils {

  private static Logger log4j = Logger.getLogger(HttpsUtils.class);

  private static KeyStore loadKeyStore(String passphrase) throws KeyStoreException {
    KeyStore ks = null;
    InputStream is = null;
    try {
      try {
        File file = new File("jssecacerts");
        if (file.isFile() == false) {
          char SEP = File.separatorChar;
          File dir = new File(System.getProperty("java.home") + SEP + "lib" + SEP + "security");
          file = new File(dir, "jssecacerts");
          if (file.isFile() == false) {
            file = new File(dir, "cacerts");
          }
        }
        log4j.info("Loading KeyStore " + file + "...");
        is = new FileInputStream(file);
        ks = KeyStore.getInstance(KeyStore.getDefaultType());
        if (passphrase == null)
          throw new KeyStoreException("Invalid passphrase: null");
        ks.load(is, passphrase.toCharArray());
      } catch (NoSuchAlgorithmException e) {
        log4j.error(e.getMessage(), e);
        throw new KeyStoreException(e.getMessage(), e);
      } catch (CertificateException e) {
        log4j.error(e.getMessage(), e);
        throw new KeyStoreException(e.getMessage(), e);
      } catch (IOException e) {
        log4j.error(e.getMessage(), e);
        throw new KeyStoreException(e.getMessage(), e);
      } finally {
        if (is != null)
          is.close();
      }
    } catch (IOException e) {
      log4j.error(e.getMessage(), e); // Error closing InputStream
    }

    return ks;
  }

  private static void installCert(URL url, String alias, String passphrase)
      throws GeneralSecurityException {

    KeyStore ks = null;
    SSLContext context = null;
    SavingTrustManager tm = null;

    String host = url.getHost();
    int port = url.getPort();
    if (port == -1)
      port = 443; // Default SSL port

    ks = loadKeyStore(passphrase);

    log4j.info("Setting up secure connection to " + host + ":" + port + "...");
    context = SSLContext.getInstance("TLS");
    TrustManagerFactory tmf =

    TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
    tmf.init(ks);
    X509TrustManager defaultTrustManager = (X509TrustManager) tmf.getTrustManagers()[0];
    tm = new SavingTrustManager(defaultTrustManager);
    context.init(null, new TrustManager[] { tm }, null);

    SSLSocket socket = null;
    SSLSocketFactory factory = null;
    try {
      factory = context.getSocketFactory();
      log4j.info("Opening connection to " + host + ":" + port + "...");
      socket = (SSLSocket) factory.createSocket(host, port);
      socket.setSoTimeout(10000);
      log4j.info("Starting SSL handshake...");
      socket.startHandshake();
      socket.close();
      log4j.info("No errors, certificate is already trusted");
      return;
    } catch (SSLException e) {
      log4j.info("Certificate not yet installed"); // OK
    } catch (IOException e) {
      log4j.error(e.getMessage(), e);
      throw new GeneralSecurityException(e.getMessage(), e);
    } finally {
      if (socket != null) {
        try {
          socket.close();
        } catch (IOException e) {
          log4j.error(e.getMessage(), e);
        }
      }
    }

    X509Certificate[] chain = tm.chain;
    if (chain == null) {
      throw new GeneralSecurityException("No certificates found at " + url.toString());
    }
    log4j.info("Server sent " + chain.length + " certificate(s):");
    for (int i = 0; i < chain.length; i++) {
      X509Certificate cert = chain[i];
      String subjectDNName = cert.getSubjectDN().getName();
      if (subjectDNName.contains("Openbravo Heartbeat")) {
        log4j.info("Found certificate matching \'Openbravo Heartbeat\'");
        OutputStream out = null;
        try {
          ks.setCertificateEntry(alias, cert);
          out = new FileOutputStream("jssecacerts");
          ks.store(out, passphrase.toCharArray());
          out.close();
          log4j.info(cert);
          log4j.info("Added certificate to keystore 'jssecacerts' using alias '" + alias + "'");
          return;
        } catch (IOException e) {
          log4j.error(e.getMessage(), e);
          throw new GeneralSecurityException(e.getMessage(), e);
        } finally {
          try {
            out.close();
          } catch (IOException e) {
            // We tried.
          }
        }
      }
    }
  }

  private static HttpsURLConnection getSecureConnection(URL url, KeyStore ks)
      throws GeneralSecurityException, SSLHandshakeException {

    String host = url.getHost();
    int port = url.getPort();
    log4j.info("Setting up secure connection to " + host + ":" + port + "...");
    SSLContext context = SSLContext.getInstance("TLS");
    TrustManagerFactory tmf =

    TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
    tmf.init(ks);
    X509TrustManager defaultTrustManager = (X509TrustManager) tmf.getTrustManagers()[0];
    SavingTrustManager tm = new SavingTrustManager(defaultTrustManager);
    context.init(null, new TrustManager[] { tm }, null);
    SSLSocketFactory factory = context.getSocketFactory();
    HttpsURLConnection.setDefaultSSLSocketFactory(factory);
    HttpsURLConnection.setDefaultHostnameVerifier(hv);

    HttpsURLConnection conn = null;
    log4j.info("Opening connection to " + host + ":" + port + "...");
    try {
      conn = (HttpsURLConnection) url.openConnection();
      conn.setDoOutput(true);
    } catch (MalformedURLException e) { // Shouldn't happen
      log4j.error(e.getMessage(), e);
    } catch (IOException e) {
      if (e instanceof SSLHandshakeException) {
        log4j.info("Could not complete SSL handshake. Server certificate is not installed.");
        log4j.error(e.getMessage(), e);
        throw (SSLHandshakeException) e;
      }
      log4j.error(e.getMessage(), e);
      throw new GeneralSecurityException(e.getMessage(), e);
    }
    return conn;
  }

  static String sendSecure(HttpsURLConnection conn, String data) throws IOException {
    String result = null;
    BufferedReader br = null;
    try {
      String s = null;
      StringBuilder sb = new StringBuilder();
      br = new BufferedReader(new InputStreamReader(sendSecureHttpsConnection(conn, data)
          .getInputStream()));
      while ((s = br.readLine()) != null) {
        sb.append(s + "\n");
      }
      br.close();
      result = sb.toString();
    } catch (IOException e) {
      log4j.error(e.getMessage(), e);
      throw e;
    }
    return result;
  }

  private static HttpsURLConnection sendSecureHttpsConnection(HttpsURLConnection conn, String data)
      throws IOException {
    BufferedWriter bw = null;
    try {
      conn.setDoOutput(true);

      bw = new BufferedWriter(new OutputStreamWriter(conn.getOutputStream()));
      bw.write(data);
      bw.flush();
      bw.close();

      return conn;
    } catch (IOException e) {
      log4j.error(e.getMessage(), e);
      throw e;
    }
  }

  public static String sendSecure(URL url, String data, String alias, String passphrase)
      throws GeneralSecurityException, IOException {
    HttpsURLConnection conn = getHttpsConn(url, alias, passphrase);
    return sendSecure(conn, data);
  }

  public static HttpURLConnection sendHttpsRequest(URL url, String data, String alias,
      String passphrase) throws GeneralSecurityException, IOException {

    HttpsURLConnection conn = getHttpsConn(url, alias, passphrase);
    return sendSecureHttpsConnection(conn, data);

  }

  public static HttpsURLConnection getHttpsConn(URL url, String alias, String passphrase)
      throws KeyStoreException, GeneralSecurityException, SSLHandshakeException {
    KeyStore ks = null;
    try {
      ks = loadKeyStore(passphrase);
    } catch (KeyStoreException e) { // Problem loading keystore
      log4j.error(e.getMessage(), e);
    }
    // check if the Certificate for alias is installed. If not, install it.
    if (ks != null && !ks.containsAlias(alias)) {
      installCert(url, alias, passphrase);
      ks = loadKeyStore(passphrase);
    }
    // Now try and establish the secure connection
    try {
      return getSecureConnection(url, ks);
    } catch (GeneralSecurityException e) {
      log4j.error(e.getMessage(), e);
      throw new SSLHandshakeException(e.getMessage());
    }
  }

  public static String encode(String queryStr, String encoding) {
    StringBuilder sb = new StringBuilder();
    String[] ss = queryStr.split("&");
    for (String s : ss) {
      String key = s.split("=")[0];
      String value = "";
      try {
        value = s.split("=")[1];
      } catch (IndexOutOfBoundsException e) {
        // Do nothing - value is an empty string
      }
      try {
        value = URLEncoder.encode(value, encoding);
      } catch (UnsupportedEncodingException e) {
        log4j.error(e.getMessage(), e);
        // Shouldn't happen. Openbravo only using UTF-8
      }
      sb.append(key + "=" + value + "&");
    }
    return sb.toString();
  }

  private static class SavingTrustManager implements X509TrustManager {

    private final X509TrustManager tm;
    private X509Certificate[] chain;

    SavingTrustManager(X509TrustManager tm) {
      this.tm = tm;
    }

    public X509Certificate[] getAcceptedIssuers() {
      throw new UnsupportedOperationException();
    }

    public void checkClientTrusted(X509Certificate[] chain, String authType)
        throws CertificateException {
      throw new UnsupportedOperationException();
    }

    public void checkServerTrusted(X509Certificate[] chain, String authType)
        throws CertificateException {
      this.chain = chain;
      tm.checkServerTrusted(chain, authType);
    }
  }

  private static HostnameVerifier hv = new HostnameVerifier() {

    public boolean verify(String urlHostName, SSLSession session) {
      log4j.info("Warning: URL Host: " + urlHostName + " vs. " + session.getPeerHost());
      return true;
    }
  };

  public static boolean isInternetAvailable() {
    return isInternetAvailable(null, 0);
  }

  public static boolean isInternetAvailable(String proxyHost, int proxyPort) {
    if (proxyHost != null && !proxyHost.equals("")) {
      System.getProperties().put("proxySet", true);
      System.getProperties().put("http.proxyHost", proxyHost);
      System.getProperties().put("https.proxyHost", proxyHost);
      System.getProperties().put("http.proxyPort", String.valueOf(proxyPort));
      System.getProperties().put("https.proxyPort", String.valueOf(proxyPort));
      System.setProperty("java.net.useSystemProxies", "true");
    } else {
      System.getProperties().put("proxySet", false);
      System.getProperties().remove("http.proxyHost");
      System.getProperties().remove("http.proxyPort");
      System.getProperties().remove("https.proxyHost");
      System.getProperties().remove("https.proxyPort");
      System.setProperty("java.net.useSystemProxies", "false");
    }
    try {
      InetAddress address = InetAddress.getByName("openbravo.com");
      log4j.info("Name: " + address.getHostName());
      log4j.info("Addr: " + address.getHostAddress());
      log4j.info("Reach: " + address.isReachable(3000));
      // Double check.
      URL url = new URL("http://www.openbravo.com");
      HttpURLConnection conn = (HttpURLConnection) url.openConnection();
      conn.setConnectTimeout(3000);
      conn.connect();
      if (conn.getResponseCode() != 200) {
        return false;
      }
    } catch (UnknownHostException e) {
      log4j.error("Unable to lookup openbravo.com", e);
      return false;
    } catch (IOException e) {
      log4j.error("Unable to reach openbravo.com", e);
      return false;
    }
    return true;
  }

}