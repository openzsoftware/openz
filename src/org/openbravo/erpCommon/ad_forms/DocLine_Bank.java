/*
 ******************************************************************************
 * The contents of this file are subject to the   Compiere License  Version 1.1
 * ("License"); You may not use this file except in compliance with the License
 * You may obtain a copy of the License at http://www.compiere.org/license.html
 * Software distributed under the License is distributed on an  "AS IS"  basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 * The Original Code is                  Compiere  ERP & CRM  Business Solution
 * The Initial Developer of the Original Code is Jorg Janke  and ComPiere, Inc.
 * Portions created by Jorg Janke are Copyright (C) 1999-2001 Jorg Janke, parts
 * created by ComPiere are Copyright (C) ComPiere, Inc.;   All Rights Reserved.
 * Contributor: Openbravo SL (C) 2001-2009 Openbravo S.L.
 * Parts created by Openbravo are Copyright (C) 2001-2009 Openbravo SL
 * Contributor:  Stefan Zimmermann, 01/2011, sz@zimmermann-software.de (SZ)
 * Parts created by Stefan Zimmermann are Copyright (C) 2011 Stefan Zimmermann
 ******************************************************************************
 */
package org.openbravo.erpCommon.ad_forms;

import java.math.*;

import javax.servlet.ServletException;

import org.apache.log4j.Logger;
import org.openbravo.database.ConnectionProvider;

public class DocLine_Bank extends DocLine {
  static Logger log4jDocLine_Bank = Logger.getLogger(DocLine_Bank.class);

  public String m_C_Payment_ID = "";
  public String m_C_GLItem_ID = "";
  public String isManual = "";
  public String chargeAmt = "";

  public String m_TrxAmt = ZERO.toString();
  public String m_StmtAmt = ZERO.toString();
  public String m_InterestAmt = ZERO.toString();
  public String convertChargeAmt = ZERO.toString();

  public DocLine_Bank(String DocumentType, String TrxHeader_ID, String TrxLine_ID) {
    super(DocumentType, TrxHeader_ID, TrxLine_ID);
  }

  /**
   * Set Amounts
   * 
   * @param StmtAmt
   *          statement amt
   * @param TrxAmt
   *          transaction amount
   */
  public void setAmount(String StmtAmt/* , String InterestAmt */, String TrxAmt) {
    if (StmtAmt != null && !StmtAmt.equals(""))
      m_StmtAmt = StmtAmt;
    /*
     * if (InterestAmt != null && !StmtAmt.equals("")) m_InterestAmt = InterestAmt;
     */
    if (TrxAmt != null && !StmtAmt.equals(""))
      m_TrxAmt = TrxAmt;
  } // setAmount

  // SZ removed GL-Items

  public String getServletInfo() {
    return "Servlet for the accounting";
  } // end of getServletInfo() method
}
