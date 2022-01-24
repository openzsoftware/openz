/*
 *************************************************************************
 * The contents of this file are subject to the Openbravo  Public  License
 * Version  1.0  (the  "License"),  being   the  Mozilla   Public  License
 * Version 1.1  with a permitted attribution clause; you may not  use this
 * file except in compliance with the License. You  may  obtain  a copy of
 * the License at http://www.openbravo.com/legal/license.html 
 * Software distributed under the License  is  distributed  on  an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific  language  governing  rights  and  limitations
 * under the License. 
 * The Original Code is Openbravo ERP. 
 * The Initial Developer of the Original Code is Openbravo SL 
 * All portions are Copyright (C) 2001-2009 Openbravo SL 
 * All Rights Reserved. 
 * Contributor(s):  ______________________________________.
 ************************************************************************
 */
package org.openbravo.erpCommon.utility;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import org.apache.log4j.Logger;

class Task extends Thread {

  private String m_cmd;
  private Process m_child;
  private StringBuffer m_out;
  private StringBuffer m_err;
  private InputStream m_outStream;
  private InputStream m_errStream;
  private OutputStream m_inStream;
  private Thread m_outReader;
  private Thread m_errReader;
  static Logger log4j = Logger.getLogger(Task.class);

  public Task(String cmd) {
    m_child = null;
    m_out = new StringBuffer();
    m_err = new StringBuffer();
    m_outReader = new Thread() {
      public void run() {
        if (log4j.isDebugEnabled())
          log4j.debug("Task.outReader.run");
        try {
          int c;
          for (; (c = m_outStream.read()) != -1 && !isInterrupted(); m_out.append((char) c))
            ;
          m_outStream.close();
        } catch (IOException ioe) {
          log4j.error("Task.outReader" + ioe);
        }
        if (log4j.isDebugEnabled())
          log4j.debug("Task.outReader.run - done");
      }
    };
    m_errReader = new Thread() {
      public void run() {
        if (log4j.isDebugEnabled())
          log4j.debug("Task.errReader.run");
        try {
          int c;
          for (; (c = m_errStream.read()) != -1 && !isInterrupted(); m_err.append((char) c))
            ;
          m_errStream.close();
        } catch (IOException ioe) {
          log4j.error("Task.errReader" + ioe);
        }
        if (log4j.isDebugEnabled())
          log4j.debug("Task.errReader.run - done");
      }
    };
    m_cmd = cmd;
  }

  public void run() {
    if (log4j.isDebugEnabled())
      log4j.debug("Task.run");
    try {
      m_child = Runtime.getRuntime().exec(m_cmd);
      m_outStream = m_child.getInputStream();
      m_errStream = m_child.getErrorStream();
      m_inStream = m_child.getOutputStream();
      if (checkInterrupted())
        return;
      m_outReader.start();
      m_errReader.start();
      if (checkInterrupted())
        return;
      m_errReader.join();
      if (checkInterrupted())
        return;
      m_outReader.join();
      if (checkInterrupted())
        return;
    } catch (Exception e) {
      log4j.error("Task.run - error: " + e);
      return;
    }
    try {
      m_child.waitFor();
    } catch (InterruptedException ie) {
    }
    try {
      if (m_child != null)
        if (log4j.isDebugEnabled())
          log4j.debug("Task.run - ExitValue=" + m_child.exitValue());
    } catch (Exception e) {
    }
    if (log4j.isDebugEnabled())
      log4j.debug("Task.run - done");
    return;
  }

  private boolean checkInterrupted() {
    if (isInterrupted()) {
      if (log4j.isDebugEnabled())
        log4j.debug("Task.checkInterrupted - true");
      if (m_child != null)
        m_child.destroy();
      m_child = null;
      if (m_outReader != null && m_outReader.isAlive())
        m_outReader.interrupt();
      m_outReader = null;
      if (m_errReader != null && m_errReader.isAlive())
        m_errReader.interrupt();
      m_errReader = null;
      if (m_inStream != null)
        try {
          m_inStream.close();
        } catch (Exception e) {
        }
      m_inStream = null;
      if (m_outStream != null)
        try {
          m_outStream.close();
        } catch (Exception e) {
        }
      m_outStream = null;
      if (m_errStream != null)
        try {
          m_errStream.close();
        } catch (Exception e) {
        }
      m_errStream = null;
      return true;
    } else {
      return false;
    }
  }

  public StringBuffer getOut() {
    return m_out;
  }

  public StringBuffer getErr() {
    return m_err;
  }

  public OutputStream getInStream() {
    return m_inStream;
  }
}
