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
package org.openbravo.erpCommon.utility;

import java.awt.Color;
import java.util.Iterator;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.design.JRDesignBand;
import net.sf.jasperreports.engine.design.JRDesignExpression;
import net.sf.jasperreports.engine.design.JRDesignExpressionChunk;
import net.sf.jasperreports.engine.design.JRDesignField;
import net.sf.jasperreports.engine.design.JRDesignLine;
import net.sf.jasperreports.engine.design.JRDesignStaticText;
import net.sf.jasperreports.engine.design.JRDesignTextField;
import net.sf.jasperreports.engine.design.JRDesignVariable;
import net.sf.jasperreports.engine.design.JasperDesign;
import net.sf.jasperreports.engine.type.StretchTypeEnum;
import net.sf.jasperreports.engine.type.CalculationEnum;

import org.apache.log4j.Logger;

class ReportDesignBO {
  public static Logger log4j = Logger.getLogger("org.openbravo.erpCommon.utility.GridBO");
  private int px = 0;
  private Boolean first=true;
  private int pageWidth = 0;

  private JasperDesign jasperDesign;

  private GridReportVO gridReportVO;
  private boolean withfooter;

  public ReportDesignBO(JasperDesign jasperDesign, GridReportVO gridReportVO, Boolean bwithfooter) {
    super();
    this.jasperDesign = jasperDesign;
    this.gridReportVO = gridReportVO;
    if (gridReportVO.getTotalWidth() + jasperDesign.getLeftMargin() + jasperDesign.getRightMargin() > jasperDesign
        .getPageWidth())
      this.jasperDesign.setPageWidth(gridReportVO.getTotalWidth() + jasperDesign.getLeftMargin()
          + jasperDesign.getRightMargin());
    this.pageWidth = jasperDesign.getPageWidth() - jasperDesign.getLeftMargin()
        - jasperDesign.getRightMargin();
    this.withfooter=bwithfooter;
  }

  private void addField(GridColumnVO columnVO) throws JRException {
    addFieldHeader(columnVO);
    addFieldValue(columnVO);
    
    if (withfooter)
      addFieldFooter(columnVO);
    px += columnVO.getWidth();
  }

  @SuppressWarnings("deprecation")
  private void addFieldHeader(GridColumnVO columnVO) {
    JRDesignBand bHeader = (JRDesignBand) jasperDesign.getColumnHeader();
    JRDesignStaticText text = new JRDesignStaticText();
    
    text.setText(columnVO.getTitle());
    text.setWidth(columnVO.getWidth());
    text.setHeight(bHeader.getHeight());
    text.setX(px);
    // Set syle
    text.setFontName(gridReportVO.getHeaderBandStyle().getFontName());
    text.setFontSize(gridReportVO.getHeaderBandStyle().getFontSize());
    text.setForecolor(gridReportVO.getHeaderBandStyle().getForeColor());
    text.setBold(gridReportVO.getHeaderBandStyle().isBold());
    text.setItalic(gridReportVO.getHeaderBandStyle().isItalic());
    text.setUnderline(gridReportVO.getHeaderBandStyle().isUnderline());
    if (!columnVO.getFieldClass().equals(java.math.BigDecimal.class)) {    
      text.setHorizontalAlignment(net.sf.jasperreports.engine.type.HorizontalAlignEnum.LEFT);
      }else{
    text.setHorizontalAlignment(net.sf.jasperreports.engine.type.HorizontalAlignEnum.RIGHT);
    }
    if (log4j.isDebugEnabled())
      log4j.debug("Field Header, field: " + columnVO.getTitle() + " Width: " + columnVO.getWidth()
          + " X: " + px);
    bHeader.addElement(text);
  }
  
  @SuppressWarnings("deprecation")
  private void addFieldFooter(GridColumnVO columnVO) throws JRException {
    JRDesignBand bFooter = (JRDesignBand) jasperDesign.getColumnFooter();
    
    if (! columnVO.getFieldClass().equals(java.math.BigDecimal.class)) {
      JRDesignStaticText text = new JRDesignStaticText();
      if (first) {
        text.setText(gridReportVO.getSumtext());
        first=false;
      } else
        text.setText("");
      text.setWidth(columnVO.getWidth());
      text.setHeight(bFooter.getHeight());
      text.setX(px);
      // Set syle
      text.setFontName(gridReportVO.getHeaderBandStyle().getFontName());
      text.setFontSize(gridReportVO.getHeaderBandStyle().getFontSize());
      text.setForecolor(gridReportVO.getHeaderBandStyle().getForeColor());
      text.setBold(gridReportVO.getHeaderBandStyle().isBold());
      text.setItalic(gridReportVO.getHeaderBandStyle().isItalic());
      text.setUnderline(gridReportVO.getHeaderBandStyle().isUnderline());
      bFooter.addElement(text);
    }
    else {
      JRDesignVariable var=new JRDesignVariable();
      var.setCalculation(CalculationEnum.SUM);
      var.setValueClass(java.math.BigDecimal.class);
      JRDesignExpressionChunk chunk = new JRDesignExpressionChunk();
      chunk.setText(columnVO.getDbName());
      chunk.setType(JRDesignExpressionChunk.TYPE_FIELD);
      JRDesignExpression expression = new JRDesignExpression();
      expression.addChunk(chunk);
      expression.setValueClass(columnVO.getFieldClass());
      var.setName(columnVO.getDbName());
      var.setExpression(expression);
      jasperDesign.addVariable(var);
      // Add the Text Field
      chunk = new JRDesignExpressionChunk();
      chunk.setText(columnVO.getDbName());
      chunk.setType(JRDesignExpressionChunk.TYPE_VARIABLE);
      expression = new JRDesignExpression();
      expression.addChunk(chunk);
      expression.setValueClass(columnVO.getFieldClass());
      JRDesignTextField textField = new JRDesignTextField();
      textField.setWidth(columnVO.getWidth());
      textField.setHeight(bFooter.getHeight());
      textField.setX(px);
      textField.setExpression(expression);
      if (columnVO.getFieldClass().equals(java.math.BigDecimal.class)) {
        if (columnVO.getPrecision()==2)
          textField.setPattern("#,##0.00;-#,##0.00");
        if (columnVO.getPrecision()==3)
          textField.setPattern("#,##0.000;-#,##0.000");
        if (columnVO.getPrecision()==4)
          textField.setPattern("#,##0.0000;-#,##0.0000");
      }
      textField.setBlankWhenNull(true);
      textField.setFontName(gridReportVO.getDetailBandStyle().getFontName());
      textField.setHorizontalAlignment(net.sf.jasperreports.engine.type.HorizontalAlignEnum.RIGHT);
      textField.setFontSize(gridReportVO.getDetailBandStyle().getFontSize());
      textField.setForecolor(gridReportVO.getDetailBandStyle().getForeColor());
      textField.setBold(true);
      textField.setItalic(gridReportVO.getDetailBandStyle().isItalic());
      textField.setUnderline(gridReportVO.getDetailBandStyle().isUnderline());
      textField.setStretchWithOverflow(true);
      textField.setStretchType(StretchTypeEnum.RELATIVE_TO_TALLEST_OBJECT);
      bFooter.addElement(textField);

    }
      

    if (log4j.isDebugEnabled())
      log4j.debug("Field Header, field: " + columnVO.getTitle() + " Width: " + columnVO.getWidth()
          + " X: " + px);
    
  }
  @SuppressWarnings("deprecation")
  private void addFieldValue(GridColumnVO columnVO) throws JRException {
    //JRDesignBand bDetalle = (JRDesignBand) jasperDesign.getDetailSection();
    JRDesignBand bDetalle = (JRDesignBand) jasperDesign.getDetailSection().getBands()[0];
    JRDesignField f = new JRDesignField();
    f.setName(columnVO.getDbName());
    f.setValueClass(columnVO.getFieldClass());
    jasperDesign.addField(f);

    JRDesignExpressionChunk chunk = new JRDesignExpressionChunk();
    chunk.setText(columnVO.getDbName());
    chunk.setType(JRDesignExpressionChunk.TYPE_FIELD);
    JRDesignExpression expression = new JRDesignExpression();
    expression.addChunk(chunk);
    expression.setValueClass(columnVO.getFieldClass());
    JRDesignTextField textField = new JRDesignTextField();
    textField.setWidth(columnVO.getWidth());
    textField.setHeight(bDetalle.getHeight());
    textField.setX(px);
    textField.setExpression(expression);
    if (columnVO.getFieldClass().equals(java.math.BigDecimal.class)) {
      if (columnVO.getPrecision()==2)
        textField.setPattern("#,##0.00;-#,##0.00");
      if (columnVO.getPrecision()==3)
        textField.setPattern("#,##0.000;-#,##0.000");
      if (columnVO.getPrecision()==4)
        textField.setPattern("#,##0.0000;-#,##0.0000");
      textField.setHorizontalAlignment(net.sf.jasperreports.engine.type.HorizontalAlignEnum.RIGHT);
    }

    textField.setBlankWhenNull(true);
    textField.setFontName(gridReportVO.getDetailBandStyle().getFontName());
    textField.setFontSize(gridReportVO.getDetailBandStyle().getFontSize());
    textField.setForecolor(gridReportVO.getDetailBandStyle().getForeColor());
    textField.setBold(gridReportVO.getDetailBandStyle().isBold());
    textField.setItalic(gridReportVO.getDetailBandStyle().isItalic());
    textField.setUnderline(gridReportVO.getDetailBandStyle().isUnderline());
    textField.setStretchWithOverflow(true);
    textField.setStretchType(StretchTypeEnum.RELATIVE_TO_TALLEST_OBJECT);

    bDetalle.addElement(textField);
  }

  public void define() throws JRException {
    if (log4j.isDebugEnabled())
      log4j.debug("Define JasperDesign, pageWidth: " + this.pageWidth);
    defineTitle(gridReportVO.getTitle());
    defineLineWidth();
    Iterator<?> it = gridReportVO.getColumns().iterator();
    // jasperDesign.getTitle().setPrintWhenExpression(false);
    while (it.hasNext()) {
      addField((GridColumnVO) it.next());
    }
  }

  private void defineTitle(String title) throws JRException {
    JRDesignBand bTitulo = (JRDesignBand) jasperDesign.getTitle();
    JRDesignStaticText text = (JRDesignStaticText) bTitulo.getElementByKey("staticTitle");
    text.setText(title);
    text.setForecolor(new Color(0,0,0));
    
  }

  private void defineLineWidth() throws JRException {
    JRDesignBand bTitulo = (JRDesignBand) jasperDesign.getTitle();
    JRDesignLine line = (JRDesignLine) bTitulo.getElementByKey("title-top-line");
    line.setWidth(this.pageWidth);
    line = (JRDesignLine) bTitulo.getElementByKey("title-bottom-line");
    line.setWidth(this.pageWidth);
    bTitulo = (JRDesignBand) jasperDesign.getColumnHeader();
    line = (JRDesignLine) bTitulo.getElementByKey("columnHeader-top-line");
    line.setWidth(this.pageWidth);
    line = (JRDesignLine) bTitulo.getElementByKey("columnHeader-bottom-line");
    line.setWidth(this.pageWidth);
    bTitulo = (JRDesignBand) jasperDesign.getPageFooter();
    line = (JRDesignLine) bTitulo.getElementByKey("pageFooter-top-line");
    line.setWidth(this.pageWidth);
  }
}
