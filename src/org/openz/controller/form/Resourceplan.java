package org.openz.controller.form;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.openbravo.base.filter.IsIDFilter;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;
import org.openbravo.data.FieldProvider;
import org.openbravo.erpCommon.businessUtility.WindowTabs;
import org.openbravo.erpCommon.info.SelectorUtility;
import org.openbravo.erpCommon.utility.ComboTableDataWrapper;
import org.openbravo.erpCommon.utility.OBError;
import org.openbravo.erpCommon.utility.Utility;
import org.openbravo.utils.Replace;
import org.openz.util.FormatUtils;
import org.openz.view.DataGrid;
import org.openz.view.Formhelper;
import org.openz.view.FormhelperData;
import org.openz.view.Scripthelper;
import org.openz.view.EditableGrid;
import org.openz.view.templates.*;
import org.openbravo.data.FResponse;


public class Resourceplan  extends HttpSecureAppServlet {
    private static final long serialVersionUID = 1L;

    public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException,
        ServletException {
      VariablesSecureApp vars = new VariablesSecureApp(request);
      
     
      
      try{
        // Get and Set Session Variables here
        //Getting
    	String nrefresh=PlanData.RefreshInterval(this);
    	DateFormat dateFormat = new SimpleDateFormat( vars.getSessionValue("#AD_JavaDateFormat"));
    	String strDatenow=dateFormat.format(new Date());
    	Calendar c = Calendar.getInstance();
    	c.add(Calendar.DATE, 60); 
    	String strDateend=dateFormat.format(c.getTime());
        String strDateFrom = vars.getDateParameterGlobalVariable("inpdatefrom", this.getClass().getName() + "|DateFrom",strDatenow,this);
        String strDateTo = vars.getDateParameterGlobalVariable("inpdateto", this.getClass().getName() + "|DateTo", strDateend,this);
        String strProject = "";
        String strWithmachines ="";
        if (vars.getCommand().equals("DEFAULT")) {
          strWithmachines =vars.getGlobalVariable("inpwithmachines", this.getClass().getName() + "|withmachines", "Y");
          strProject =vars.getGlobalVariable("inpcProjectId", this.getClass().getName() + "|c_project_id", "");
        }
        else {//Commmand=FIND
          strWithmachines = vars.getStringParameter("inpwithmachines");
          strProject =vars.getStringParameter("inpcProjectId");
          vars.setSessionValue(this.getClass().getName() + "|c_project_id", strProject);
          if (strWithmachines.equals("")) {
            strWithmachines = "N";
            vars.setSessionValue(this.getClass().getName() + "|withmachines","N");
          } else // Y
            vars.setSessionValue(this.getClass().getName() + "|withmachines","Y");
        }
        String strOrg = vars.getGlobalVariable("inpadOrgId", this.getClass().getName() + "|AD_ORG_ID", vars.getOrg());
        String strPlanOrCotract=vars.getGlobalVariable("inpplandata", this.getClass().getName() + "|plandata", "Order");
        if (strPlanOrCotract.equals("Proposal"))
          strPlanOrCotract="Planned"; // more easy than alter all items-Procedure needs this string for Proposals
        String strLayout=vars.getGlobalVariable("inplayout", this.getClass().getName() + "|layout", "Small");
        //Additional javascripts
        
        //Setting 
        String strPdcInfobar=""; //Area for further Information of the Servlet
        Scripthelper script= new Scripthelper();
        // Set Scrollers
        String strTopScroller=vars.getStringParameter("inpscrolltop");
        if ( strTopScroller.isEmpty())
          strTopScroller="0";
        String strLeftScroller=vars.getStringParameter("inpscrolleft");
        if ( strLeftScroller.isEmpty())
          strLeftScroller="0";
        script.addHiddenfieldWithID("scrolltop", strTopScroller);
        script.addHiddenfieldWithID("scrolleft", strLeftScroller);
        script.addOnload("stashaction(scrollToPosition('client'," + strTopScroller +"," + strLeftScroller + "),1);");
        // Add Org ID as hidden field (there is none in our Fieldgroups and org is needed By popups)
        //script.addHiddenfield("inpadOrgId", strOrg);
        //initialize the grids
        //initialize the Fieldgroups
        //Header Fieldgroup
        String strHeaderFG="";
        
        //Resourceplan
        String strResourceplan="";
        //The Structure of the Servlet
        String strSkeleton="";
        //Html Output of the Servlet
        String strOutput ="" ;
        //Calling the Formhelper to create the Fieldgroups and Grids
        Formhelper fh=new Formhelper();
        Date now=new Date();
        // Do the Business Logic HERE

        strPdcInfobar=fh.prepareInfobar(this, vars, script, "In dieser Maske erhalten Sie nach Eingabe des Zeitraums eine Übersicht aller Mitarbeiter mit dazugehörigen Tätigkeiten an bestimmten Daten.","");

        // Prepare the Fieldgroups from AD                    Name of the Fieldgroup
        //Fieldgroups below are Default for PDC
        //Header Fieldgroup
        strHeaderFG=fh.prepareFieldgroup(this, vars, script, "FilterResourceplan", null,false);
        
        // Loading the Lower Grid from AD          Name of lower grid  
        // Load Form-Skeleton 
        WindowTabs tabs;                  //The Servlet Name generated automatically
        tabs = new WindowTabs(this, vars, this.getClass().getName());
        //Defining the toolbar default no toolbar
        String strToolbar=FormhelperData.getFormToolbar(this, this.getClass().getName());
         //Loading the structure                                                       Name of the Servlet     
        strSkeleton = ConfigureFrameWindow.doConfigure(this,vars,"inpbarcode",null, "Resourceplan",strToolbar,"NONE",tabs);
        if (vars.commandIn("FIND")||vars.commandIn("DEFAULT")||vars.commandIn("SAVE")){
       	 
         if (strLayout.equals("Small")){ 
   	 	strResourceplan=PlanData.createPlanSmall(this, strDateFrom,"dd-MM-yyyy", strDateTo,strOrg ,strPlanOrCotract,strWithmachines,strProject);			
        strHeaderFG=Replace.replace(strHeaderFG, "<table cellspacing=\"0\" cellpadding=\"0\" class=\"Form_Table\">","<table cellspacing=\"0\" id=\"filter\" cellpadding=\"0\" class=\"Form_Table\" style=\"width:101%;float:left;top:-80px;left:-19px;position:absolute;height:112px;z-index:9;\">"); 
        strSkeleton=Replace.replace(strSkeleton, "id=\"client\"", "id=\"client\" onscroll=\"document.getElementById('scrolltop').value=this.scrollTop;document.getElementById('scrolleft').value=this.scrollLeft;if(parent.isMenuHide==false){document.getElementById('xtFzCol').style.left=((this.scrollLeft-3));document.getElementById('xtHead').style.top=((this.scrollLeft-9));document.getElementById('filter').style.left=((this.scrollLeft-19));if(this.scrollTop>=1){document.getElementById('xtFzRow').style.top=((this.scrollTop)+3);document.getElementById('filter').style.top=((this.scrollTop)-80);}else{document.getElementById('xtFzRow').style.top=(+4);document.getElementById('filter').style.top=(-80);}}else{document.getElementById('xtFzCol').style.left=((this.scrollLeft-3));document.getElementById('xtHead').style.top=((this.scrollLeft-9));document.getElementById('filter').style.left=((this.scrollLeft-19));if(this.scrollTop>=1){document.getElementById('xtFzRow').style.top=((this.scrollTop)+4);document.getElementById('filter').style.top=((this.scrollTop)-97);}else{document.getElementById('xtFzRow').style.top=(0);document.getElementById('filter').style.top=(-97);}}\"");   
        
         }else{
   	 	strResourceplan=PlanData.createPlan(this, strDateFrom,"dd-MM-yyyy", strDateTo,strOrg ,strPlanOrCotract);
        strHeaderFG=Replace.replace(strHeaderFG, "<table cellspacing=\"0\" cellpadding=\"0\" class=\"Form_Table\">","<table cellspacing=\"0\" id=\"filter\" cellpadding=\"0\" class=\"Form_Table\" style=\"width:101%;float:left;top:-67px;left:-13px;position:absolute;height:112px;z-index:9;\">"); 
        strSkeleton=Replace.replace(strSkeleton, "id=\"client\"", "id=\"client\"  onscroll=\"document.getElementById('scrolltop').value=this.scrollTop;document.getElementById('scrolleft').value=this.scrollLeft;if(parent.isMenuHide==false){document.getElementById('xtFzCol').style.left=((this.scrollLeft-3));document.getElementById('filter').style.left=((this.scrollLeft-14));document.getElementById('xtHead').style.left=((this.scrollLeft-3));if(this.scrollTop>=57){document.getElementById('xtFzRow').style.top=((this.scrollTop)-5);document.getElementById('filter').style.top=((this.scrollTop)-67);}else{document.getElementById('xtFzRow').style.top=(+1);document.getElementById('filter').style.top=(-71)}}else{document.getElementById('xtFzCol').style.left=((this.scrollLeft-4));document.getElementById('filter').style.left=((this.scrollLeft-19));document.getElementById('xtHead').style.left=((this.scrollLeft-4));if(this.scrollTop>=57){document.getElementById('xtFzRow').style.top=((this.scrollTop)+1);document.getElementById('filter').style.top=((this.scrollTop)-71);}else{document.getElementById('xtFzRow').style.top=(0);document.getElementById('filter').style.top=(-71)}};\"");
        //strSkeleton=Replace.replace(strSkeleton,"onresize=\"onResizeDo();\"","onresize=\"onResizeDo();if(parent.isMenuHide==false){document.getElementById('filter').style.left=(-19px);document.getElementById('filter').style.top=(24px);}else{document.getElementById('filter').style.left=(-13px);document.getElementById('filter').style.top=(29px);}\"");
         }
        }


        //strSkeleton=Replace.replace(strSkeleton, "onload=\"onLoadDo();\"","onload=\"onLoadDo();resourceplanadjust();\"");
        if (vars.getLanguage().equals("en_US")){
          strResourceplan=Replace.replace(strResourceplan, "Datum", "Date");
          strResourceplan=Replace.replace(strResourceplan, "Mitarbeiter", "Employee");
        }
        strOutput=Replace.replace(strSkeleton, "@CONTENT@",  strHeaderFG+strResourceplan  );
        //strOutput=Replace.replace(strSkeleton, "@CONTENT@", strPdcInfobar+strHeaderFG+strResourceplan  ); 
        //Generating html source
        if (nrefresh.equals("0")){
        strOutput = script.doScript(strOutput,"",this,vars);}
        else{
        	String javascriptrefresh="<script type=\"text/javascript\">setTimeout(function () {window.location = window.location.href;}, "+Integer.parseInt(nrefresh)+" * 60000)</script>";
        	strOutput = script.doScript(strOutput,javascriptrefresh,this,vars);
        }
        // Gerenrate response
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println(strOutput);
        out.close();
      }
      catch (Exception e) { 
        log4j.error("Error in : " + this.getClass().getName() +"\n" + e.getMessage());
        e.printStackTrace();
         throw new ServletException(e);
 
       }  
 }
    
    public String getServletInfo() {
      return this.getClass().getName();
    } // end of getServletInfo() method
  }

