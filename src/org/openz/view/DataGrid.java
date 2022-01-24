package org.openz.view;
/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2012 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.Sqlc;
import org.openbravo.utils.Replace;
import org.openbravo.base.filter.RequestFilter;
import org.openbravo.base.filter.ValueListFilter;

public class DataGrid {
     public class Column {
       public String width;
       public String name;
       public String elementid;
       // DECIMAL, PRICE, DATE, STRING . if empty, STRING is assumed
       public String datatype;
       public String dynSql;
       public String dynSqlFilter;
       public String getDatatype(){
         if (datatype==null)
           return "STRING";
         else
           return datatype;
       }
       public boolean issortcol;
     }
     public class Rowkey {
       public String name;
       // DECIMAL, PRICE, DATE, STRING . if empty, STRING is assumed
       public String datatype;
       public String getDatatype(){
         if (datatype==null)
           return "STRING";
         else
           return datatype;
       }
       public String suffix;
     }
     public Column[] columns;
     public Rowkey[] rowKeys;
     public String keycolumname;
     public RequestFilter columnfilter;
     public final RequestFilter directionfilter = new ValueListFilter("asc", "desc");
     
     
     public void initGridByAD(String gridname,VariablesSecureApp vars,HttpSecureAppServlet servlet) throws Exception {
       String refID=GridData.getReferenceID(servlet,gridname);
       GridData[] data=GridData.selectSimpleGridColumns(servlet, refID);
       keycolumname=Sqlc.TransformaNombreColumna(GridData.getDetailsIDField(servlet, refID));
       columns = new Column[Integer.parseInt(GridData.getVisibleCount(servlet, refID))+1];
       String[] colnames = new String[Integer.parseInt(GridData.getVisibleCount(servlet, refID))+1];
       rowKeys = new Rowkey[Integer.parseInt(GridData.getRowKeyCount(servlet, refID))];
       Column cl=new Column();
       int j=0;
       int h=0;
       Rowkey rk = new Rowkey();
       String dtype="STRING";
       for (int i = 0; i < data.length; i++){
         cl.name=Sqlc.TransformaNombreColumna(data[i].name);
         cl.elementid=data[i].adElementId;
         cl.width=data[i].colspan;
         cl.dynSql=Replace.replace(data[i].dynsqlvalue, "@SQL=", "");
         cl.dynSqlFilter=Replace.replace(data[i].dynsqlfilter,"@SQL=", "");
         if (data[i].template.equals("DECIMAL") || data[i].template.equals("PRICE"))
           dtype=data[i].template;
         else
           dtype="STRING";
         cl.datatype=dtype;
         cl.issortcol=data[i].issortable.equals("Y") ? true : false;
         if (data[i].isdisplayed.equals("Y")) {
           columns[h]=cl;
           colnames[h]=Sqlc.TransformaNombreColumna(data[i].name);
           h++;
         }
         cl=new Column();
         if (data[i].isrowkey.equals("Y")){
           rk.name=data[i].name;
           rk.datatype=dtype;
           rk.suffix=data[i].rowkeysuffix;
           rowKeys[j]=rk;
           j++;
           rk=  new Rowkey();
         }
       }
       cl=new Column();
       cl.datatype="KEY";
       cl.name="rowkey";
       cl.issortcol=false;
       cl.width="0";
       cl.elementid="";
       columns[h]=cl;
       colnames[h]="rowkey";
       columnfilter= new ValueListFilter(colnames);
     }    
     public String getDynSQL(String columname) {
    	 for (int i=0;i<columns.length;i++) {
    		 if (columns[i].name.equals(columname)&&!(columns[i].dynSql==null)&&!columns[i].dynSql.isEmpty())
    			 return columns[i].dynSql;
    	 }
    	 return "''"; 
     }
     public String getDynFilter(String columname, String filtervalue) {
    	 if (filtervalue==null || filtervalue.isEmpty())
    		 return null;
    	 for (int i=0;i<columns.length;i++) {
    		 if (columns[i].name.equals(columname))
    			 return Replace.replace(columns[i].dynSqlFilter,"@FILTERVALUE@", filtervalue);
    	 }
    	 return null; 
     }
}
