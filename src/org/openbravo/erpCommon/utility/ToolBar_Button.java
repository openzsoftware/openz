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

class ToolBar_Button implements HTMLElement {
  String name = "";
  String description = "";
  String click = "";
  String href = "#";
  ToolBar_Image image;
  String base_direction;
  String imageClass;
  boolean selected = false;

  public ToolBar_Button(String _base_direction, String _name, String _description, String _onclick) {
    this(_base_direction, _name, _description, _onclick, "#");
  }

  public ToolBar_Button(String _base_direction, String _name, String _description, String _onclick,
      boolean _selected) {
    this(_base_direction, _name, _description, _onclick, "#");
    this.selected = _selected;
  }

  public ToolBar_Button(String _base_direction, String _name, String _description, String _onclick,
      boolean _selected, String _imageClass) {
    this(_base_direction, _name, _description, _onclick, "#", _imageClass);
    this.selected = _selected;
  }

  public ToolBar_Button(String _base_direction, String _name, String _description, String _onclick,
      String _href) {
    this(_base_direction, _name, _description, _onclick, _href, _name);
  }

  public ToolBar_Button(String _base_direction, String _name, String _description, String _onclick,
      String _href, String _imageClass) {
    this.base_direction = _base_direction;
    this.name = _name;
    this.click = _onclick;
    this.description = _description;
    this.href = _href;
    this.imageClass = _imageClass;
    this.image = new ToolBar_Image(this.base_direction, this.name, this.description,
        this.imageClass);
  }

  public String getWidth() {
    return "2%";
  }

  public String elementType() {
    return "BUTTON";
  }

  public String toString() {
    StringBuffer toolbar = new StringBuffer();
    toolbar.append("<a href=\"");
    toolbar.append(href);
    toolbar.append("\" onClick=\"");
    toolbar.append(click);
    if ((click != null && !click.equals("")) || href == null || href.equals("") || href.equals("#"))
      toolbar.append("return false;");
    toolbar.append("\" ");
    toolbar.append("class=\"Main_ToolBar_Button").append(selected ? "_Selected" : "");
    //.append(
    //    "\" onMouseOver=\"window.status='");
    //toolbar.append(description);
    //toolbar.append("';return true;\" ");
    toolbar
        .append("\"  onblur=\"this.hideFocus=false\" ");
    toolbar.append("id=\"linkButton").append(name).append("\">");
    toolbar.append(image);
    toolbar.append("</a>");
    return toolbar.toString();
  }
}
