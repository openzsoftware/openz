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
package org.openbravo.erpCommon.ad_forms;

import java.io.IOException;

import org.apache.log4j.Logger;
import org.openbravo.base.VariablesBase;
import org.openbravo.data.FieldProvider;

class FileLoadData extends MultipartRequest2 {
  static Logger log4j = Logger.getLogger(FileLoadData.class);
  public boolean newline = false;
  public String overlines = "";
  public int counter = 0;
  public String[] textarray;


  
  public FileLoadData() {
  }
  
  public FileLoadData(VariablesBase _vars, String _filename, boolean _firstLineHeads, String _format)
	      throws IOException {
	    super(_vars, _filename, _firstLineHeads, _format, null);
	  }
  
  public FileLoadData(VariablesBase _vars, String _filename, boolean _firstLineHeads,
	      String _format, FieldProvider[] _data) throws IOException {
	    super(_vars, _filename, _firstLineHeads, _format, _data);
	  }
  
  public FileLoadData(VariablesBase _vars, String _filename, boolean _firstLineHeads,
      String _format, FieldProvider[] _data, String countrows) throws IOException {
    super(_vars, _filename, _firstLineHeads, _format, _data, countrows);
  }

  public FileLoadData(VariablesBase _vars, String _filename, boolean _firstLineHeads, String _format, String countrows)
      throws IOException {
    super(_vars, _filename, _firstLineHeads, _format, null, countrows);
  }
  


  public FieldProvider lineSeparatorFormated(String line) {
    if (line == null || line.length() < 1)
      return null;
    if (counter == 0)
    	textarray  = new String[255];
    if (overlines == null)
    	overlines = "";
    int last = 0;
    int first = 0;
   	String text = "";
    FileLoadData fileLoadData = new FileLoadData();
    if (line.contains("\"\"")) {
    	line = line.replaceAll("\"\"", "");
    }
    while (last < line.length()) {
	    if ((line.startsWith(format, first) && !newline)) {
	    	last++;
	    	text = "";
	    } else if (line.charAt(first) == '"' && newline) {
	    		text = overlines;
	    		last=last+2;
	    		newline = false;
	    } else if (line.charAt(first) == '"' || newline) {
	    	if(line.indexOf('"'+format, last + 1) != -1) {
	    		if (!newline)
	    			first++;
		        last = line.indexOf('"'+format, last + 1);
		        newline = false;
		        text=overlines+line.substring(first, last);
		        last = last +2;
	    	} else if ( line.indexOf('"', last + 1) != -1) {
	    		if (!newline)
	    			first++;
	            last = line.indexOf('"', last + 1);
	            newline = false;
	            text=overlines+line.substring(first, last);
	            last++;
	        } else {
	    		if (!newline)
	    			first++;
	        	last = line.length();
	        	newline = true;
	        	overlines=overlines+line.substring(first, last)+"\n";
	        }     	
	    } 
	    first = last;
	    if (!newline) {
	        try {
	            if (log4j.isDebugEnabled())
	              log4j.debug("FileLoadData - setFieldProvider - text = " + text);
	            textarray[counter] = text;
	            counter++;
	            overlines = "";
	          } catch (Exception e) {
	            log4j.warn("File.load: " + e);
	          }
	        // TODO SZ: very dirty throw to prevent endless loop
	        if (counter> Integer.parseInt(rowcount))
	          counter=counter/0;
	    }
    }
    if (line.endsWith(format) && !newline && last >= line.length()) {
    	text = "";
        try {
            if (log4j.isDebugEnabled())
              log4j.debug("FileLoadData - setFieldProvider - text = " + text);
            textarray[counter] = text;
            counter++;
            overlines = "";
          } catch (Exception e) {
            log4j.warn("File.load: " + e);
          }
    }
    if (counter== Integer.parseInt(rowcount)) {
    	for (int i = 0; i < counter; i++) {
    		fileLoadData.addField(textarray[i]);
    	}
    	counter=0;
    	return fileLoadData;
    } else return null;
  }

}
