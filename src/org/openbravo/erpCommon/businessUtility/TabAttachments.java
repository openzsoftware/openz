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
package org.openbravo.erpCommon.businessUtility;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.fileupload.FileItem;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.SequenceIdData;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.FileUtility;
import org.openbravo.utils.Replace;
import org.openbravo.xmlEngine.XmlDocument;
import org.openz.util.FileUtils;
import org.openz.util.ProcessUtils;
import org.openz.view.EditableGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.templates.ConfigureFrameWindow;
import org.openz.view.templates.ConfigurePopup;
import org.zsoft.ecommerce.FilePollingAPI;
import org.zsoft.ecommerce.FilePollingTAB;

public class TabAttachments extends HttpSecureAppServlet {
  private static final long serialVersionUID = 1L;

  @Override
  public void init(ServletConfig config) {
    super.init(config);
    boolHist = false;
  }

  @Override
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
      ServletException {
	Vector <String> retval;
	
    final VariablesSecureApp vars = new VariablesSecureApp(request);
    OBError myMessage = null;

    if (vars.getCommand().startsWith("SAVE_NEW")) {
        final String strTab = vars.getSessionValue("TabAttachments.tabId");
        final String key = vars.getSessionValue("TabAttachments.key");
      
        final String strText = vars.getStringParameter("inptext");
        final String strDataType = vars.getStringParameter("inpadDatatypeId");
        final TabAttachmentsData[] data = TabAttachmentsData.selectTabInfo(this, strTab);
      String tableId = "";
      if (data == null || data.length == 0)
        throw new ServletException("Tab not found: " + strTab);
      else
        tableId = data[0].adTableId;
      if (!vars.getSessionValue("TabAttachments.uploadtype").isEmpty()) {
          try {
        	  final OBError oberUpload = customUpload(vars,  tableId, key, vars.getSessionValue("TabAttachments.uploadtype"));
        	  ProcessUtils.displayMsgPopupClose(this, vars, request, response, "Upload", oberUpload );
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			throw new ServletException(e.getMessage());
		}
          return;
      }
      final String strFileReference = SequenceIdData.getUUID();
      final OBError oberrInsert = insert(vars, strFileReference, tableId, key, strDataType, strText);
      if (!oberrInsert.getType().equals("Success")) {
        vars.setMessage("TabAttachments", oberrInsert);
        response.sendRedirect(strDireccion + request.getServletPath() + "?Command=DEFAULT");
      } else {
        if (vars.commandIn("SAVE_NEW_RELATION")) {
         // response.sendRedirect(strDireccion + request.getServletPath()
         //     + "?Command=DEFAULT&inpcFileId=" + strFileReference);
        	printPageFS(response, vars);
        } else if (vars.commandIn("SAVE_NEW_EDIT")) {
          response.sendRedirect(strDireccion + request.getServletPath()
              + "?Command=EDIT&inpcFileId=" + strFileReference);
        } else if (vars.commandIn("SAVE_NEW_NEW")) {
          response.sendRedirect(strDireccion + request.getServletPath() + "?Command=NEW");
        }
      }
    } else if (vars.getCommand().startsWith("SAVE_EDIT")) {
        final String strTab = vars.getSessionValue("TabAttachments.tabId");
        final String strWindow = vars.getSessionValue("inpwindowId");
        final String key = vars.getSessionValue("TabAttachments.key");
	    String strFileReference = vars.getStringParameter("inpcFileId");
	    EditableGrid grid;
      try {
		grid = new EditableGrid("TabAttachmentsGrid", vars, this);
		retval=grid.getSelectedIds(null, vars, "C_File_ID");
		
		for (int i = 0; i < retval.size(); i++) {
			 strFileReference=retval.elementAt(i);
             String Text=grid.getValue(this, vars, retval.elementAt(i), "description");
             String strName=grid.getValue(this, vars, retval.elementAt(i), "name");
             String DataType=grid.getValue(this, vars, retval.elementAt(i), "ad_datatype_id");
             String strLine=grid.getValue(this, vars, retval.elementAt(i), "line");
             //if((DataType.equals("")) || (DataType != null)) {
             //	 DataType=strName.substring(strName.length()-3,strName.length());               
             //    DataType=FileUtils.evalFile(DataType);
             //}
             if (strLine.isEmpty())
            	 strLine="10";
             int check= TabAttachmentsData.update(this, vars.getUser(), DataType, Text, strLine,strFileReference);
             
             vars.setSessionValue("updatecheck", Integer.toString(check));
		}
             if ((vars.getSessionValue("updatecheck")) == Integer.toString(0)) {
                 myMessage = new OBError();
                 myMessage.setType("Success");
                 myMessage.setTitle("");
                 myMessage.setMessage(Utility.messageBD(this, "Error", vars.getLanguage()));
                 vars.setMessage("TabAttachments", myMessage);
                 // vars.setSessionValue("TabAttachments.message",
                 // Utility.messageBD(this, "Error", vars.getLanguage()));
                 response.sendRedirect(strDireccion + request.getServletPath() + "?Command=EDIT&inpcFileId="
                     + strFileReference);
               } else {
                 if (vars.commandIn("SAVE_EDIT_RELATION")) {
                   response.sendRedirect(strDireccion + request.getServletPath()
                       + "?Command=DEFAULT&inpcFileId=" + strFileReference);
                 } else if (vars.commandIn("SAVE_EDIT_EDIT")) {
                   response.sendRedirect(strDireccion + request.getServletPath()
                       + "?Command=EDIT&inpcFileId=" + strFileReference);
                 } else if (vars.commandIn("SAVE_EDIT_NEW")) {
                   response.sendRedirect(strDireccion + request.getServletPath() + "?Command=NEW&inpKey="
                       + key);
                 } else if (vars.commandIn("SAVE_EDIT_NEXT")) {
                   final TabAttachmentsData[] data = TabAttachmentsData.selectTabInfo(this, strTab);
                   String tableId = "";
                   if (data == null || data.length == 0)
                     throw new ServletException("Tab not found: " + strTab);
                   else {
                     tableId = data[0].adTableId;
                     if (data[0].isreadonly.equals("Y"))
                       throw new ServletException("This tab is read only");
                   }
                   final String strNewFile = TabAttachmentsData.selectNext(this, Utility.getContext(this,
                       vars, "#User_Client", strWindow), Utility.getContext(this, vars,
                       "#AccessibleOrgTree", strWindow), strFileReference, tableId, key);
                   if (!strNewFile.equals(""))
                     strFileReference = strNewFile;
                   response.sendRedirect(strDireccion + request.getServletPath()
                       + "?Command=EDIT&inpcFileId=" + strFileReference);
                 }
               }
		
	} catch (Exception e) {
		
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
      printPageFS(response, vars);
    } else if (vars.commandIn("DEL")) {
    	EditableGrid grid;
	        
	        	try {
					grid = new EditableGrid("TabAttachmentsGrid", vars, this);
					retval=grid.getSelectedIds(null, vars, "C_File_ID");
			  		for (int i = 0; i < retval.size(); i++) {
			  			String filesi=retval.elementAt(i);
			  			final OBError oberrDelete = delete(vars, filesi);
			  				if (!oberrDelete.getType().equals("Success")) {
			  					vars.setMessage("TabAttachments", oberrDelete);
			  					response.sendRedirect(strDireccion + request.getServletPath() + "?Command=DEFAULT");
			  				} else{
			  					
			  				}
			  		}
				} catch (Exception e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
	        	response.sendRedirect(strDireccion + request.getServletPath());
	        }

            
  		 else if (vars.commandIn("RESTORE")) {
  		
        final String strTab = vars.getSessionValue("TabAttachments.tabId");
        final TabAttachmentsData[] data = TabAttachmentsData.selectTabInfo(this, strTab);
        String tableId = "";
        if (data == null || data.length == 0)
          throw new ServletException("Tab not found: " + strTab);
        else
          tableId = data[0].adTableId;
        final String key = vars.getSessionValue("TabAttachments.key");
        final OBError oberrDelete = restore(vars, tableId,key);
        if (!oberrDelete.getType().equals("Success")) {
          vars.setMessage("TabAttachments", oberrDelete);
          response.sendRedirect(strDireccion + request.getServletPath() + "?Command=DEFAULT");
        } else
          response.sendRedirect(strDireccion + request.getServletPath());
      } else if (vars.commandIn("DISPLAY_DATA")) {
    	  EditableGrid grid;
    	  
				try {
					grid = new EditableGrid("TabAttachmentsGrid", vars, this);
					retval=grid.getSelectedIds(null, vars, "C_File_ID");
					
					if (retval.size()>0) {
			  			String filesi=retval.elementAt(0);
			  			printPageFile(response, vars, filesi);
			  		}
				} catch (Exception e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				
		  		
      printPageFS(response, vars);
    }
    	else if (vars.commandIn("DEFAULT")) {
		      vars.getGlobalVariable("inpTabId", "TabAttachments.tabId");
		      vars.getGlobalVariable("inpwindowId", "TabAttachments.windowId");
		      vars.getGlobalVariable("inpKey", "TabAttachments.key");
		      vars.getGlobalVariable("inpEditable", "TabAttachments.editable","Y");  
		      vars.removeSessionValue("TabAttachments.uploadtype");
		      printPageFS(response, vars);
    } else if (vars.commandIn("UPLOAD")) {
    		  String strTab=vars.getGlobalVariable("inpTabId", "TabAttachments.tabId");
	          String strWindow=vars.getGlobalVariable("inpwindowId", "TabAttachments.windowId");
	          String key=vars.getGlobalVariable("inpKey", "TabAttachments.key");
	          vars.getGlobalVariable("inpEditable", "TabAttachments.editable","Y"); 
	          String upt=vars.getGlobalVariable("inpUploadType", "TabAttachments.uploadtype");
	          printPageEdit(response, vars, strTab, strWindow, key, "");
    } else if (vars.commandIn("FRAME1", "RELATION")) {
		      final String strTab = vars.getSessionValue("TabAttachments.tabId");
		      final String strWindow = vars.getSessionValue("TabAttachments.windowId");
		      final String key = vars.getSessionValue("TabAttachments.key");
		      final boolean editable = vars.getGlobalVariable("inpEditable", "TabAttachments.editable","Y").equals("Y");
		      printPage(response, vars, strTab, strWindow, key, editable);
    } else if (vars.commandIn("FRAME2")) {
    			whitePage(response);
    } else if (vars.commandIn("EDIT")) {
		       final String strTab = vars.getSessionValue("TabAttachments.tabId");
		       final String strWindow = vars.getSessionValue("TabAttachments.windowId");
		       final String key = vars.getSessionValue("TabAttachments.key");
		       final String strFileReference = vars.getRequiredStringParameter("inpcFileId");
		       printPageEdit(response, vars, strTab, strWindow, key, strFileReference);
    } else if (vars.commandIn("NEW")) {
    		   String strTab = vars.getStringParameter("inpTabId");
    		   if (strTab.isEmpty())
    			   strTab=vars.getSessionValue("TabAttachments.tabId");
    		   else
    			   vars.setSessionValue("TabAttachments.tabId",strTab);
    		   final String strWindow = vars.getSessionValue("TabAttachments.windowId");
    		   String key =  vars.getStringParameter("inpKey");
    		   if (key.isEmpty())
    			   key = vars.getSessionValue("TabAttachments.key");
    		   else
    			   vars.setSessionValue("TabAttachments.key",key);
    		   if (key.isEmpty())
    			   throw new ServletException("No Data selected");
			   printPageEdit(response, vars, strTab, strWindow, key, "");
    } else if (vars.commandIn("DISPLAY_DATA")) {
    		final String strFileReference = vars.getRequiredStringParameter("inpcFileId");
    		printPageFile(response, vars, strFileReference);
    } else if (vars.commandIn("CHECK")) {
        	String strTab=vars.getGlobalVariable("inpTabId", "TabAttachments.tabId");      
        	String key=vars.getGlobalVariable("inpKey", "TabAttachments.key");
        	String window=vars.getGlobalVariable("inpwindowId", "TabAttachments.windowId");

      printPageCheck(response, vars, strTab, key);
    } else
      pageError(response);
  }

  private OBError insert(VariablesSecureApp vars, String strFileReference, String tableId,
      String key, String strDataType, String strText) throws IOException, ServletException {

    OBError myMessage = null;
    myMessage = new OBError();
    myMessage.setTitle("");

    if (log4j.isDebugEnabled())
      log4j.debug("Deleting records");
    Connection conn = null;
    try {
      conn = this.getTransactionConnection();
      final String inpName = "inpname";
      String strName = "";
    //  final FileItem file = vars.getMultiFile(inpName);
      final Vector<FileItem> filez = vars.getMultiFiles(inpName);
      if (filez==null)
    	  throw new ServletException("Empty file");
      for(int f=0; f<=filez.size()-1; f++) {
   //   if (file == null)
   //     throw new ServletException("Empty file");
      //strName = file.getName();
      
      strName = filez.get(f).getName();
      strDataType=strName.substring(strName.length()-3,strName.length());
      strDataType= FileUtils.evalFile(strDataType);
      int i = strName.lastIndexOf("\\");
      if (i != -1) {
        strName = strName.substring(i + 1);

      } else if ((i = strName.lastIndexOf("/")) != -1) {
        strName = strName.substring(i + 1);
      }
      if (f>0) {
    	  strFileReference = SequenceIdData.getUUID();
      }
      String lineno="";
      TabAttachmentsData.insertta(conn, this, strFileReference, vars.getClient(), vars.getOrg(), vars
          .getUser(), tableId, key, strDataType, strText, strName);
      try {
        final File uploadedDir = new File(globalParameters.strFTPDirectory + "/" + tableId + "-"
            + key);
        if (!uploadedDir.exists())
          uploadedDir.mkdirs();
        final File uploadedFile = new File(uploadedDir, strName);
        if (uploadedFile.exists())
          throw new ServletException("File " + uploadedFile.getName() + " already exists. Choose a different name.");
        filez.get(f).write(uploadedFile);
        //file.write(uploadedFile);

      } catch (final Exception ex) {
        throw new ServletException(ex);
      }
      
    }releaseCommitConnection(conn);
    } catch (final Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (final Exception ignored) {
      }
      e.printStackTrace();
      log4j.error("Rollback in transaction");
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, e.getMessage(), vars.getLanguage()));
      return myMessage;
      // return "ProcessRunError";
    }
    myMessage.setType("Success");
    myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    return myMessage;
    // return "";
  }

  private OBError delete(VariablesSecureApp vars, String strFileReference) throws IOException,
      ServletException {
    OBError myMessage = null;
    myMessage = new OBError();
    myMessage.setTitle("");

    if (log4j.isDebugEnabled())
      log4j.debug("Deleting records");
    Connection conn = null;
    try {
      conn = this.getTransactionConnection();
      final TabAttachmentsData[] data = TabAttachmentsData.selectReference(this, strFileReference);
      TabAttachmentsData.insertDeleted(conn, this, vars.getUser(), vars.getLanguage(), strFileReference);
      TabAttachmentsData.delete(conn, this, strFileReference);
      try {
        FileUtility f = new FileUtility();

        final File file = new File(globalParameters.strFTPDirectory + "/" + data[0].adTableId + "-"
            + data[0].adRecordId, data[0].name);
        if (file.exists())
          f = new FileUtility(globalParameters.strFTPDirectory + "/" + data[0].adTableId + "-"
              + data[0].adRecordId, data[0].name, false);
        else
          f = new FileUtility(globalParameters.strFTPDirectory, strFileReference, false);
        /*
        if (f.exists()) {
          if (!f.deleteFile()) {
            myMessage.setType("Error");
            myMessage.setMessage(Utility.messageBD(this, "ProcessRunError", vars.getLanguage()));
            return myMessage;
          }
        }
        */
      } catch (final Exception ex) {
        throw new ServletException(ex);
      }
      releaseCommitConnection(conn);
    } catch (final Exception e) {
      try {
        releaseRollbackConnection(conn);
      } catch (final Exception ignored) {
      }
      e.printStackTrace();
      log4j.error("Rollback in transaction");
      myMessage.setType("Error");
      myMessage.setMessage(Utility.messageBD(this, e.getMessage(), vars.getLanguage()));
      return myMessage;
      // return "ProcessRunError";
    }
    myMessage.setType("Success");
    myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
    return myMessage;
    // return "";
  }
  
  private OBError restore(VariablesSecureApp vars, String strTableId, String strKey) throws IOException,
  		ServletException {
	OBError myMessage = null;
	myMessage = new OBError();
	myMessage.setTitle("");
	
	if (log4j.isDebugEnabled())
	  log4j.debug("Restoring records");
	Connection conn = null;
	try {
	  conn = this.getTransactionConnection();
	  TabAttachmentsData.restoreDeleted(conn, this, strTableId, strKey);
	  TabAttachmentsData.restoreDeletedDEL(conn, this, strTableId, strKey);
	  releaseCommitConnection(conn);
	} catch (final Exception e) {
	  try {
	    releaseRollbackConnection(conn);
	  } catch (final Exception ignored) {
	  }
	  e.printStackTrace();
	  log4j.error("Rollback in transaction");
	  myMessage.setType("Error");
	  myMessage.setMessage(Utility.messageBD(this, e.getMessage(), vars.getLanguage()));
	  return myMessage;
	  // return "ProcessRunError";
	}
	myMessage.setType("Success");
	myMessage.setMessage(Utility.messageBD(this, "Success", vars.getLanguage()));
	return myMessage;
	// return "";
}

  private void printPageFS(HttpServletResponse response, VariablesSecureApp vars)
      throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Attachments relations frame set");
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/businessUtility/TabAttachments_FS").createXmlDocument();

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
  }

  private void printPage(HttpServletResponse response, VariablesSecureApp vars, String strTab,
      String strWindow, String key, boolean editable) throws IOException, ServletException {
	    Scripthelper script= new Scripthelper();
	    response.setContentType("text/html; charset=UTF-8");
	   
	    String strGrid1="";    
	    String strSkeleton=""; //Structure
	    String strOutput ="" ; //The html-code as Output
	    String btns="";
	    EditableGrid grid;
	    Formhelper fh=new Formhelper();
	  if (log4j.isDebugEnabled())
      log4j.debug("Output: Frame 1 of the attachments relations");
    final String[] discard = { "noData", "","restorable" };
    if (!editable)
      discard[1] = "editable";
    final TabAttachmentsData[] data = TabAttachmentsData.selectTabInfo(this, strTab);
    String tableId = "";
    if (data == null || data.length == 0)
      throw new ServletException("Tab not found: " + strTab);
    else {
      tableId = data[0].adTableId;
      if (data[0].isreadonly.equals("Y")) {
        discard[0] = new String("selReadOnly");
    	  btns="";
      }
    }

    final TabAttachmentsData[] files = TabAttachmentsData.select(this,Utility.getContext(this,
        vars, "#User_Client", strWindow), Utility.getContext(this, vars, "#AccessibleOrgTree",
        strWindow), tableId, key);
    
    if ((files == null) || (files.length == 0))	{   
        try {
        	discard[0] = "widthData";
        	btns=fh.prepareFieldgroup(this, vars, script, "TabAttachmentsNew", null,false);
        }catch (Exception e) {
    		// TODO Auto-generated catch block
    		e.printStackTrace(); 
    	}}else {
    try {
    	btns=fh.prepareFieldgroup(this, vars, script, "TabAttachmentsButtons", null,false);
    	grid = new EditableGrid("TabAttachmentsGrid", vars, this);
    	strGrid1=grid.printGrid(this, vars, script, files);
    	// Direct Download JS Patch
    	strGrid1=Replace.replace(strGrid1,"sendDirectLink(document.frmMain, 'c_file_id', '', '../utility/ReferencedLink.html', '", "directFileDownload('");
    	strGrid1=Replace.replace(strGrid1,"', '800028', '_self', true);;return false;","');submitCommandForm('DISPLAY_DATA', false, null, 'TabAttachments_F1.html', '_self');");
    }catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}}
    // Restore deleted Attachments..
    if (TabAttachmentsData.hasDeleted(this, Utility.getContext(this, vars, "#AccessibleOrgTree",
            strWindow), tableId, key).equals("Y"))
		try {
			discard[2] = "";
			btns=fh.prepareFieldgroup(this, vars, script, "TabAttachmentsButtons", null,false)+fh.prepareFieldgroup(this, vars, script, "TabAttachmentsRestore", null,false);
		} catch (Exception e2) {
			// TODO Auto-generated catch block
			e2.printStackTrace();
		}
    
    String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
	 WindowTabs tabs;                  //The Servlet Name generated automatically
    try {
		tabs = new WindowTabs(this, vars, this.getClass().getName());
	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
    
    try {
		strSkeleton = ConfigurePopup.doConfigure(this,vars,null, "Tab Attachments",strToolbar);
		strSkeleton=strSkeleton.replace("onunload=\"pageunload();\"", "");
	} catch (Exception e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	}
    strOutput=Replace.replace(strSkeleton, "@CONTENT@",strGrid1+btns);
 
    try {
    	// Direct Download Function
    	script.addJScript("function directFileDownload(thisid){\n" + 
    			"    var obj=document.getElementById(thisid);\n" + 
    			"    obj.checked=true;\n" + 
    			"    gridLineCheckboxClick(thisid);\n" + 
    			"}");
    	script.addOnload("top.opener.checkAttachmentIcon();");
    	script.addMessage(this, vars, vars.getMessage("TabAttachments"));
    	vars.removeMessage("TabAttachments");
		strOutput = script.doScript(strOutput, "",this,vars);
	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(strOutput);
    out.close();
  }

  private void printPageEdit(HttpServletResponse response, VariablesSecureApp vars, String strTab,
      String strWindow, String key, String strFileReference) throws IOException, ServletException {
    if (log4j.isDebugEnabled())
      log4j.debug("Output: Frame 1 of the attachments edition");
    final String[] discard = { "editDiscard" };
    final TabAttachmentsData[] data = TabAttachmentsData.selectTabInfo(this, strTab);
    if (data == null || data.length == 0)
      throw new ServletException("Tab not found: " + strTab);
    else {
      if (data[0].isreadonly.equals("Y"))
        throw new ServletException("This tab is read only");
    }
    if (strFileReference.equals(""))
      discard[0] = new String("newDiscard");
    
  
    final TabAttachmentsData[] files = TabAttachmentsData.selectEdit(this, strFileReference);
    final XmlDocument xmlDocument = xmlEngine.readXmlTemplate(
        "org/openbravo/erpCommon/businessUtility/TabAttachments_Edition", discard)
        .createXmlDocument();

    xmlDocument.setParameter("directory", "var baseDirectory = \"" + strReplaceWith + "/\";\n");
    xmlDocument.setParameter("language", "defaultLang=\"" + vars.getLanguage() + "\";");
    xmlDocument.setParameter("theme", vars.getTheme());
    xmlDocument.setParameter("tab", strTab);
    xmlDocument.setParameter("window", strWindow);
    xmlDocument.setParameter("key", key);
    xmlDocument.setParameter("save", (strFileReference.equals("") ? "NEW" : "EDIT"));
    xmlDocument.setParameter("recordIdentifier", TabAttachmentsData.selectRecordIdentifier(this,
        key, vars.getLanguage(), strTab));

    {
      final OBError myMessage = vars.getMessage("TabAttachments");
      vars.removeMessage("TabAttachments");
      if (myMessage != null) {
        xmlDocument.setParameter("messageType", myMessage.getType());
        xmlDocument.setParameter("messageTitle", myMessage.getTitle());
        xmlDocument.setParameter("messageMessage", myMessage.getMessage());
      }
    }

  

    xmlDocument.setData("structure1", (strFileReference.equals("") ? TabAttachmentsData.set()
        : files));
    xmlDocument.setData("reportAD_Datatype_ID_D", "liststructure", DataTypeComboData.select(this,
        Utility.getContext(this, vars, "#User_Client", "TabAttachments"), Utility.getContext(this,
            vars, "#AccessibleOrgTree", "TabAttachments")));

    response.setContentType("text/html; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.println(xmlDocument.print());
    out.close();
    
    
  }

  private void printPageFile(HttpServletResponse response, VariablesSecureApp vars,
      String strFileReference) throws IOException, ServletException {
    final TabAttachmentsData[] data = TabAttachmentsData.selectEdit(this, strFileReference);
    if (data == null || data.length == 0)
      throw new ServletException("Missing file");
    FileUtility f = new FileUtility();
    final File file = new File(globalParameters.strFTPDirectory + "/" + data[0].adTableId + "-"
        + data[0].adRecordId, data[0].name);
    if (file.exists())
      f = new FileUtility(globalParameters.strFTPDirectory + "/" + data[0].adTableId + "-"
          + data[0].adRecordId, data[0].name, false, true);
    else
      f = new FileUtility(globalParameters.strFTPDirectory, strFileReference, false, true);
    if (data[0].datatypeContent.equals(""))
      response.setContentType("application/txt");
    else
      response.setContentType(data[0].datatypeContent);
    response.setHeader("Content-Disposition", "attachment; filename=\""
        + data[0].name.replace("\"", "\\\"") + "\"");

    f.dumpFile(response.getOutputStream());
    response.getOutputStream().flush();
    response.getOutputStream().close();
  }

  private void printPageCheck(HttpServletResponse response, VariablesSecureApp vars, String strTab,
      String recordId) throws IOException, ServletException {
    response.setContentType("text/plain; charset=UTF-8");
    final PrintWriter out = response.getWriter();
    out.print(Utility.hasTabAttachments(this, vars, strTab, recordId));
    out.close();
  }
  
  private OBError customUpload(VariablesSecureApp vars,  String tableId,
	      String key, String strUploadType) throws Exception {
	  OBError myMessage = null;
	  if (strUploadType.equals("CMTSLINES")) {
	  	  Object obj = Class.forName("com.openz.custommodules.tscat.PollingOrderLines").getConstructor().newInstance();
	  	  FilePollingTAB reg = (FilePollingTAB) obj;
	      final FileItem file = vars.getMultiFile("inpname");
	      final File uploadedFile = new File("/tmp/", file.getName());
	      if (uploadedFile.exists())
	    	  uploadedFile.delete();
	      file.write(uploadedFile);
	      uploadedFile.setReadable(true);
	      myMessage =reg.fetchAndProcess(this, vars, "/tmp/" ,file.getName(),tableId,key);
	  } else { 
		  myMessage = new OBError();
		  myMessage.setType("Error");
		  myMessage.setTitle("Error: Upload Type not found");
		  myMessage.setMessage(strUploadType);
	  }
	  return myMessage;
  }

  @Override
  public String getServletInfo() {
    return "Servlet that presents the attachments";
  } // end of getServletInfo() method
}
