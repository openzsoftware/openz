
/* 2012-11-29 MH new: table zssm_ptasktechdoc, view zssm_worksteptechdoc_v */
SELECT zsse_DropView ('zssm_worksteptechdoc_v');
CREATE OR REPLACE VIEW zssm_worksteptechdoc_v AS
SELECT
  zssm_ptasktechdoc_id AS zssm_worksteptechdoc_v_id,
  zssm_ptasktechdoc_id,
  ad_client_id,
  ad_org_id,
  c_projecttask_id AS zssm_workstep_v_id,
  c_projecttask_id AS zssm_workstep_prp_v_id,
  isactive,
  created,
  createdby,
  updated,
  updatedby,
  name,
  zssm_techdoc_url
FROM zssm_ptasktechdoc;

CREATE OR REPLACE RULE zssm_worksteptechdoc_v_insert AS
ON INSERT TO zssm_worksteptechdoc_v DO INSTEAD
INSERT INTO zssm_ptasktechdoc (
  zssm_ptasktechdoc_id,
  ad_client_id,
  ad_org_id,
  c_projecttask_id,
  isactive,
  created,
  createdby,
  updated,
  updatedby,
  name,
  zssm_techdoc_url
) VALUES (
  NEW.zssm_worksteptechdoc_v_id,
  NEW.ad_client_id,
  NEW.ad_org_id,
  coalesce(NEW.zssm_workstep_v_id,NEW.zssm_workstep_prp_v_id),
  COALESCE(NEW.isactive,'Y'),
  COALESCE(NEW.created, now()),
  NEW.createdby,
  COALESCE(NEW.updated, now()),
  NEW.updatedby,
  NEW.name,
  NEW.zssm_techdoc_url);

CREATE OR REPLACE RULE zssm_worksteptechdoc_v_update AS
ON UPDATE TO zssm_worksteptechdoc_v DO INSTEAD
UPDATE zssm_ptasktechdoc SET
  zssm_ptasktechdoc_id = NEW.zssm_ptasktechdoc_id,
  ad_client_id = NEW.ad_client_id,
  ad_org_id = NEW.ad_org_id,
  c_projecttask_id = NEW.zssm_workstep_v_id,
  isactive = NEW.isactive,
  created = NEW.created,
  createdby = NEW.createdby,
  updated = NEW.updated,
  updatedby = NEW.updatedby,
  name = NEW.name,
  zssm_techdoc_url = NEW.zssm_techdoc_url
WHERE
  zssm_ptasktechdoc.zssm_ptasktechdoc_id = NEW.zssm_ptasktechdoc_id;

CREATE OR REPLACE RULE zssm_worksteptechdoc_v_delete AS
ON DELETE TO zssm_worksteptechdoc_v DO INSTEAD
DELETE FROM zssm_ptasktechdoc WHERE
  zssm_ptasktechdoc.zssm_ptasktechdoc_id = old.zssm_ptasktechdoc_id;


select zsse_DropView ('zssm_feedback_v');
create or replace view zssm_feedback_v as
select
 zspm_ptaskfeedbackline_id AS zssm_feedback_v_id,
 ad_client_id,
 ad_org_id,
 isactive,
 created,
 createdby,
 updated,
 updatedby,
 c_project_id AS zssm_productionorder_v_id,
 c_projecttask_id AS zssm_workstep_v_id,
 ad_user_id,
 ma_machine_id,
 description,
 workdate,
 hour_from,
 hour_to,
 actualcostamount,
 c_salary_category_id,
 hours,
 url
from zspm_ptaskfeedbackline;


/* 2012-11-09 MH column c_projectphase_id removed */
SELECT zsse_DropView ('zssm_workstep_v');
CREATE OR REPLACE VIEW zssm_workstep_v AS
SELECT
  prt.c_projecttask_id AS zssm_workstep_v_id,
  prt.c_projecttask_id AS c_projecttask_id,
  prj.c_project_id,
  prj.projectstatus,
  prt.c_task_id AS c_task_id,
  prt.ad_client_id AS ad_client_id,
  prt.ad_org_id AS ad_org_id,
  prt.isactive AS isactive,
  prt.created AS created,
  prt.createdby AS createdby,
  prt.updated AS updated,
  prt.updatedby AS updatedby,
  prt.c_project_id AS zssm_productionorder_v_id,
  prj.name AS zssm_prj_name,
  prj.projectcategory AS zssm_prj_projectcategory,
  prt.seqno AS seqno,
  prt.taskbegun AS taskbegun,
  prt.value AS value,
  prt.name AS name,
  prt.description AS description,
  prt.help AS help,
  prt.m_product_id AS m_product_id,
  prt.qty AS qty,
  prt.startdate AS startdate,
  prt.enddate AS enddate,
  prt.iscomplete AS iscomplete,
  prt.priceactual AS priceactual,
  prt.committedamt AS committedamt,
  prt.iscommitceiling AS iscommitceiling,
  prt.datecontract AS datecontract,
  prt.schedulestatus AS schedulestatus,
  prt.actualcost AS actualcost,
  prt.plannedcost AS plannedcost,
  prt.percentdone AS percentdone,
  prt.outsourcing AS outsourcing,
  prt.ismaterialdisposed AS ismaterialdisposed,
  prt.istaskcancelled AS istaskcancelled,
  prt.createbom AS createbom,
  prt.planmaterial AS planmaterial,
  prt.unplanmaterial AS unplanmaterial,
  prt.canceltask AS canceltask,
  prt.begintask AS begintask,
  prt.endtask AS endtask,
  prt.materialcost AS materialcost,
  prt.indirectcost AS indirectcost,
  prt.machinecost AS machinecost,
  prt.invoicedamt AS invoicedamt,
  prt.expenses AS expenses,
  prt.servcost AS servcost,
  prt.materialcostplan AS materialcostplan,
  prt.indirectcostplan AS indirectcostplan,
  prt.machinecostplan AS machinecostplan,
  prt.servcostplan AS servcostplan,
  prt.getmaterialfromstock AS getmaterialfromstock,
  prt.gotopurchasing AS gotopurchasing,
  prt.returnmaterialtostock AS returnmaterialtostock,
  prt.c_orderline_id AS c_orderline_id,
  prt.assembly AS assembly,
  prt.qtyproduced AS qtyproduced,
  prt.qty - prt.qtyproduced AS qtyleft,
  prt.receiving_locator AS receiving_locator,
  prt.issuing_locator AS issuing_locator,
  prt.percentrejects AS percentrejects,
  prt.started,
  prt.ended,
  prt.startonlywithcompletematerial,
  prt.forcematerialscan,
  prt.zssm_productionplan_task_id,
  prt.timeperpiece,
  prt.setuptime,
  prt.isautotriggered,
  trunc((prt.timeplanned/60)) as timeplanned,
  prt.weightproportion,
  prt.triggerreason,
  prt.c_color_id,
  prt.isautocloseworkstep,
  prt.m_attributesetinstance_id,
  prj.isapproved,
  (select string_agg(m.name,',') from ma_machine m,zspm_ptaskmachineplan mp where mp.ma_machine_id=m.ma_machine_id and mp.c_projecttask_id=prt.c_projecttask_id) as workplace
FROM c_projecttask prt, c_project prj
WHERE 1=1
 AND prt.c_project_id = prj.c_project_id
 AND prt.c_project_id IS NOT NULL
 AND prj.projectcategory='PRO' ;




create or replace rule zssm_workstep_v_insert as
on insert to zssm_workstep_v do instead
insert into c_projecttask (
  c_projecttask_id,
  c_task_id,
  ad_client_id,
  ad_org_id,
  isactive,
  created,
  createdby,
  updated,
  updatedby,
  seqno,
  name,
  description,
  help,
  m_product_id,
  qty,
  startdate,
  enddate,
  iscomplete,
  priceactual,
  committedamt,
  iscommitceiling,
  datecontract,
  schedulestatus,
  actualcost,
  plannedcost,
  percentdone,
  outsourcing,
  taskbegun,
  ismaterialdisposed,
  istaskcancelled,
  createbom,
  planmaterial,
  unplanmaterial,
  canceltask,
  begintask,
  endtask,
  materialcost,
  indirectcost,
  machinecost,
  invoicedamt,
  expenses,
  servcost,
  materialcostplan,
  indirectcostplan,
  machinecostplan,
  servcostplan,
  c_project_id,
  getmaterialfromstock,
  gotopurchasing,
  returnmaterialtostock,
  c_orderline_id,
  value,
  assembly,
  issuing_locator,
  receiving_locator,
  percentrejects,
  startonlywithcompletematerial,
  forcematerialscan,
  zssm_productionplan_task_id,
  started,
  ended,
  timeperpiece,
  setuptime,
  isautotriggered,
  weightproportion,
  triggerreason,
  c_color_id,
  isautocloseworkstep,
  m_attributesetinstance_id
)
values (
  NEW.zssm_workstep_v_id,
  NEW.c_task_id,
  NEW.ad_client_id,
  NEW.ad_org_id,
  COALESCE(NEW.isactive,'Y'),
  COALESCE(NEW.created, now()),
  NEW.createdby,
  COALESCE(NEW.updated, now()),
  NEW.updatedby,
  NEW.seqno,
  NEW.name,
  NEW.description,
  NEW.help,
  NEW.m_product_id,
  COALESCE(NEW.qty, 0),
  NEW.startdate,
  NEW.enddate,
  COALESCE(NEW.iscomplete, 'N'),
  NEW.priceactual,
  NEW.committedamt,
  COALESCE(NEW.iscommitceiling, 'N'),
  NEW.datecontract,
  COALESCE(NEW.schedulestatus, 'OK'),
  NEW.actualcost,
  NEW.plannedcost,
  NEW.percentdone,
  COALESCE(NEW.outsourcing, 'N'),
  COALESCE(NEW.taskbegun, 'N'),
  COALESCE(NEW.ismaterialdisposed, 'N'),
  COALESCE(NEW.istaskcancelled, 'N'),
  COALESCE(NEW.createbom, 'N'),
  COALESCE(NEW.planmaterial, 'N'),
  COALESCE(NEW.unplanmaterial, 'N'),
  COALESCE(NEW.canceltask, 'N'),
  COALESCE(NEW.begintask, 'N'),
  COALESCE(NEW.endtask, 'N'),
  NEW.materialcost,
  NEW.indirectcost,
  NEW.machinecost,
  NEW.invoicedamt,
  NEW.expenses,
  NEW.servcost,
  NEW.materialcostplan,
  NEW.indirectcostplan,
  NEW.machinecostplan,
  NEW.servcostplan,
  NEW.zssm_productionorder_v_id,
  COALESCE(NEW.getmaterialfromstock, 'N'),
  COALESCE(NEW.gotopurchasing, 'N'),
  COALESCE(NEW.returnmaterialtostock, 'N'),
  NEW.c_orderline_id,
  NEW.value,
  COALESCE(NEW.assembly, 'Y'),
  NEW.issuing_locator,
  NEW.receiving_locator,
  NEW.percentrejects,
  COALESCE(NEW.startonlywithcompletematerial, 'N'),
  COALESCE(NEW.forcematerialscan, 'N'),
  NEW.zssm_productionplan_task_id,
  NEW.started,
  NEW.ended,
  COALESCE(NEW.timeperpiece,0),
  COALESCE(NEW.setuptime,0),
  NEW.isautotriggered,
  coalesce(new.weightproportion,0),
  NEW.triggerreason,
  NEW.c_color_id,
  NEW.isautocloseworkstep,
  NEW.m_attributesetinstance_id
);

create or replace rule zssm_workstep_v_update as
on update to zssm_workstep_v do instead
update c_projecttask set
  c_projecttask_id = NEW.zssm_workstep_v_id,
  c_task_id = NEW.c_task_id,
  ad_client_id = NEW.ad_client_id,
  ad_org_id = NEW.ad_org_id,
  isactive = NEW.isactive,
  created = NEW.created,
  createdby = NEW.createdby,
  updated = NEW.updated,
  updatedby = NEW.updatedby,
  seqno = NEW.seqno,
  name = NEW.name,
  description = NEW.description,
  help = NEW.help,
  m_product_id = NEW.m_product_id,
  qty = NEW.qty,
  startdate = NEW.startdate,
  enddate = NEW.enddate,
  iscomplete = NEW.iscomplete,
  priceactual = NEW.priceactual,
  committedamt = NEW.committedamt,
  iscommitceiling = NEW.iscommitceiling,
  datecontract = NEW.datecontract,
  schedulestatus = NEW.schedulestatus,
  actualcost = NEW.actualcost,
  plannedcost = NEW.plannedcost,
  percentdone = NEW.percentdone,
  outsourcing = NEW.outsourcing,
  taskbegun = NEW.taskbegun,
  ismaterialdisposed = NEW.ismaterialdisposed,
  istaskcancelled = NEW.istaskcancelled,
  createbom = NEW.createbom,
  planmaterial = NEW.planmaterial,
  unplanmaterial = NEW.unplanmaterial,
  canceltask = NEW.canceltask,
  begintask = NEW.begintask,
  endtask = NEW.endtask,
  materialcost = NEW.materialcost,
  indirectcost = NEW.indirectcost,
  machinecost = NEW.machinecost,
  invoicedamt = NEW.invoicedamt,
  expenses = NEW.expenses,
  servcost = NEW.servcost,
  materialcostplan = NEW.materialcostplan,
  indirectcostplan = NEW.indirectcostplan,
  machinecostplan = NEW.machinecostplan,
  servcostplan = NEW.servcostplan,
  c_project_id = NEW.zssm_productionorder_v_id,
  getmaterialfromstock = NEW.getmaterialfromstock,
  gotopurchasing = NEW.gotopurchasing,
  returnmaterialtostock = NEW.returnmaterialtostock,
  c_orderline_id = NEW.c_orderline_id,
  value = NEW.value,
  assembly = NEW.assembly,
  issuing_locator = NEW.issuing_locator,
  receiving_locator = NEW.receiving_locator,
  percentrejects = NEW.percentrejects,
  startonlywithcompletematerial = NEW.startonlywithcompletematerial,
  forcematerialscan = NEW.forcematerialscan,
  zssm_productionplan_task_id = NEW.zssm_productionplan_task_id,
  started = NEW.started,
  ended = NEW.ended,
  timeperpiece=COALESCE(NEW.timeperpiece,0),
  setuptime=COALESCE(NEW.setuptime,0),
  isautotriggered=NEW.isautotriggered,
  weightproportion=NEW.weightproportion,
  triggerreason=NEW.triggerreason,
  c_color_id=NEW.c_color_id,
  isautocloseworkstep=NEW.isautocloseworkstep,
  m_attributesetinstance_id=NEW.m_attributesetinstance_id
where
  c_projecttask.c_projecttask_id = NEW.c_projecttask_id;

create or replace rule zssm_workstep_v_delete as
on delete to zssm_workstep_v do instead
delete from c_projecttask where
	c_projecttask.c_projecttask_id = old.c_projecttask_id;


SELECT zsse_DropView ('zssm_productionplan_v');
CREATE OR REPLACE VIEW zssm_productionplan_v AS
SELECT
	c_project.c_project_id AS zssm_productionplan_v_id,
	c_project.c_project_id AS c_project_id,
	c_project.ad_client_id AS ad_client_id,
	c_project.ad_org_id AS ad_org_id,
	c_project.isactive AS isactive,
	c_project.created AS created,
	c_project.createdby AS createdby,
	c_project.updated AS updated,
	c_project.updatedby AS updatedby,
	c_project.value AS value,
	c_project.name AS name,
	c_project.description AS description,
	c_project.note AS note,
	c_project.issummary AS issummary,
	c_project.ad_user_id AS ad_user_id,
	c_project.c_bpartner_id AS c_bpartner_id,
	c_project.c_bpartner_location_id AS c_bpartner_location_id,
	c_project.poreference AS poreference,
	c_project.c_paymentterm_id AS c_paymentterm_id,
	c_project.c_currency_id AS c_currency_id,
	c_project.createtemppricelist AS createtemppricelist,
	c_project.m_pricelist_version_id AS m_pricelist_version_id,
	c_project.c_campaign_id AS c_campaign_id,
	c_project.iscommitment AS iscommitment,
	c_project.plannedamt AS plannedamt,
	c_project.plannedqty AS plannedqty,
	c_project.plannedmarginamt AS plannedmarginamt,
	c_project.committedamt AS committedamt,
	c_project.datecontract AS datecontract,
	c_project.datefinish AS datefinish,
	c_project.generateto AS generateto,
	c_project.processed AS processed,
	c_project.salesrep_id AS salesrep_id,
	c_project.copyfrom AS copyfrom,
	c_project.c_projecttype_id AS c_projecttype_id,
	c_project.committedqty AS committedqty,
	c_project.invoicedamt AS invoicedamt,
	c_project.invoicedqty AS invoicedqty,
	c_project.projectbalanceamt AS projectbalanceamt,
	c_project.c_phase_id AS c_phase_id,
	c_project.iscommitceiling AS iscommitceiling,
	c_project.m_warehouse_id AS m_warehouse_id,
	c_project.projectcategory AS projectcategory,
	c_project.processing AS processing,
	c_project.publicprivate AS publicprivate,
	c_project.projectstatus AS projectstatus,
	c_project.projectkind AS projectkind,
	c_project.billto_id AS billto_id,
	c_project.projectphase AS projectphase,
	c_project.generateorder AS generateorder,
	c_project.changeprojectstatus AS changeprojectstatus,
	c_project.c_location_id AS c_location_id,
	c_project.m_pricelist_id AS m_pricelist_id,
	c_project.paymentrule AS paymentrule,
	c_project.invoice_toproject AS invoice_toproject,
	c_project.plannedpoamt AS plannedpoamt,
	c_project.lastplannedproposaldate AS lastplannedproposaldate,
	c_project.document_copies AS document_copies,
	c_project.accountno AS accountno,
	c_project.expexpenses AS expexpenses,
	c_project.expmargin AS expmargin,
	c_project.expreinvoicing AS expreinvoicing,
	c_project.responsible_id AS responsible_id,
	c_project.servcost AS servcost,
	c_project.servmargin AS servmargin,
	c_project.servrevenue AS servrevenue,
	c_project.setprojecttype AS setprojecttype,
	c_project.startdate AS startdate,
	c_project.a_asset_id AS a_asset_id,
	c_project.schedulestatus AS schedulestatus,
	c_project.actualcostamount AS actualcostamount,
	c_project.percentdoneyet AS percentdoneyet,
	c_project.estimatedamt AS estimatedamt,
	c_project.qtyofproduct AS qtyofproduct,
	c_project.m_product_id AS m_product_id,
	c_project.closeproject AS closeproject,
	c_project.materialcost AS materialcost,
	c_project.indirectcost AS indirectcost,
	c_project.machinecost AS machinecost,
	c_project.expenses AS expenses,
	c_project.reopenproject AS reopenproject,
	c_project.isdefault,
	c_project.timeperpiece,
	c_project.setuptime,
	c_project.isautotriggered  
FROM c_project
WHERE c_project.projectcategory = 'PRP';

CREATE OR REPLACE RULE zssm_productionplan_v_insert AS
ON INSERT TO zssm_productionplan_v DO INSTEAD
INSERT INTO c_project (
	c_project_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	value,
	name,
	description,
	note,
	issummary,
	ad_user_id,
	c_bpartner_id,
	c_bpartner_location_id,
	poreference,
	c_paymentterm_id,
	c_currency_id,
	createtemppricelist,
	m_pricelist_version_id,
	c_campaign_id,
	iscommitment,
	plannedamt,
	plannedqty,
	plannedmarginamt,
	committedamt,
	datecontract,
	datefinish,
	generateto,
	processed,
	salesrep_id,
	copyfrom,
	c_projecttype_id,
	committedqty,
	invoicedamt,
	invoicedqty,
	projectbalanceamt,
	c_phase_id,
	iscommitceiling,
	m_warehouse_id,
	projectcategory,
	processing,
	publicprivate,
	projectstatus,
	projectkind,
	billto_id,
	projectphase,
	generateorder,
	changeprojectstatus,
	c_location_id,
	m_pricelist_id,
	paymentrule,
	invoice_toproject,
	plannedpoamt,
	lastplannedproposaldate,
	document_copies,
	accountno,
	expexpenses,
	expmargin,
	expreinvoicing,
	responsible_id,
	servcost,
	servmargin,
	servrevenue,
	setprojecttype,
	startdate,
	a_asset_id,
	schedulestatus,
	actualcostamount,
	percentdoneyet,
	estimatedamt,
	qtyofproduct,
	m_product_id,
	closeproject,
	materialcost,
	indirectcost,
	machinecost,
	expenses,
	reopenproject,
	isdefault,
	isautotriggered  
) VALUES (
	NEW.zssm_productionplan_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
	COALESCE(NEW.isactive, 'Y'),
	COALESCE(NEW.created, now()),
	NEW.createdby,
	COALESCE(NEW.updated, now()),
	NEW.updatedby,
	NEW.value,
	NEW.name,
	NEW.description,
	NEW.note,
  COALESCE(NEW.issummary, 'N'),
  NEW.ad_user_id,
	NEW.c_bpartner_id,
	NEW.c_bpartner_location_id,
	NEW.poreference,
	NEW.c_paymentterm_id,
	NEW.c_currency_id,
	COALESCE(NEW.createtemppricelist,'Y'),
	NEW.m_pricelist_version_id,
	NEW.c_campaign_id,
	COALESCE(NEW.iscommitment, 'Y'),
	COALESCE(NEW.plannedamt, 0),
	COALESCE(NEW.plannedqty, 0),
	COALESCE(NEW.plannedmarginamt, 0),
	COALESCE(NEW.committedamt, 0),
	NEW.datecontract,
	NEW.datefinish,
	NEW.generateto,
	COALESCE(NEW.processed, 'N'),
	NEW.salesrep_id,
	NEW.copyfrom,
	NEW.c_projecttype_id,
	COALESCE(NEW.committedqty, 0),
	COALESCE(NEW.invoicedamt, 0),
	COALESCE(NEW.invoicedqty, 0),
	COALESCE(NEW.projectbalanceamt, 0),
	NEW.c_phase_id,
	COALESCE(NEW.iscommitceiling, 'N'),
	NEW.m_warehouse_id,
	COALESCE(NEW.projectcategory, 'PRP'),
	NEW.processing,
	NEW.publicprivate,
	NEW.projectstatus,
	NEW.projectkind,
	NEW.billto_id,
	NEW.projectphase,
	COALESCE(NEW.generateorder, 'N'),
	COALESCE(NEW.changeprojectstatus, 'N'),
	NEW.c_location_id,
	NEW.m_pricelist_id,
	NEW.paymentrule,
	COALESCE(NEW.invoice_toproject, 'N'),
	COALESCE(NEW.plannedpoamt, 0),
	NEW.lastplannedproposaldate,
	NEW.document_copies,
	NEW.accountno,
	NEW.expexpenses,
	NEW.expmargin,
	NEW.expreinvoicing,
	NEW.responsible_id,
	NEW.servcost,
	NEW.servmargin,
	NEW.servrevenue,
	NEW.setprojecttype,
	NEW.startdate,
	NEW.a_asset_id,
	COALESCE(NEW.schedulestatus, 'OK'),
	NEW.actualcostamount,
	NEW.percentdoneyet,
	NEW.estimatedamt,
	NEW.qtyofproduct,
	NEW.m_product_id,
	COALESCE(NEW.closeproject, 'N'),
	NEW.materialcost,
	NEW.indirectcost,
	NEW.machinecost,
	NEW.expenses,
	COALESCE(NEW.reopenproject, 'N'),
	NEW.isdefault,
	new.isautotriggered  
);

CREATE OR REPLACE RULE zssm_productionplan_v_update AS
ON UPDATE TO zssm_productionplan_v DO INSTEAD
UPDATE c_project SET
	c_project_id = NEW.zssm_productionplan_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	value = NEW.value,
	name = NEW.name,
	description = NEW.description,
	note = NEW.note,
	issummary = NEW.issummary,
	ad_user_id = NEW.ad_user_id,
	c_bpartner_id = NEW.c_bpartner_id,
	c_bpartner_location_id = NEW.c_bpartner_location_id,
	poreference = NEW.poreference,
	c_paymentterm_id = NEW.c_paymentterm_id,
	c_currency_id = NEW.c_currency_id,
	createtemppricelist = NEW.createtemppricelist,
	m_pricelist_version_id = NEW.m_pricelist_version_id,
	c_campaign_id = NEW.c_campaign_id,
	iscommitment = NEW.iscommitment,
	plannedamt = NEW.plannedamt,
	plannedqty = NEW.plannedqty,
	plannedmarginamt = NEW.plannedmarginamt,
	committedamt = NEW.committedamt,
	datecontract = NEW.datecontract,
	datefinish = NEW.datefinish,
	generateto = NEW.generateto,
	processed = NEW.processed,
	salesrep_id = NEW.salesrep_id,
	copyfrom = NEW.copyfrom,
	c_projecttype_id = NEW.c_projecttype_id,
	committedqty = NEW.committedqty,
	invoicedamt = NEW.invoicedamt,
	invoicedqty = NEW.invoicedqty,
	projectbalanceamt = NEW.projectbalanceamt,
	c_phase_id = NEW.c_phase_id,
	iscommitceiling = NEW.iscommitceiling,
	m_warehouse_id = NEW.m_warehouse_id,
	projectcategory = NEW.projectcategory,
	processing = NEW.processing,
	publicprivate = NEW.publicprivate,
	projectstatus = NEW.projectstatus,
	projectkind = NEW.projectkind,
	billto_id = NEW.billto_id,
	projectphase = NEW.projectphase,
	generateorder = NEW.generateorder,
	changeprojectstatus = NEW.changeprojectstatus,
	c_location_id = NEW.c_location_id,
	m_pricelist_id = NEW.m_pricelist_id,
	paymentrule = NEW.paymentrule,
	invoice_toproject = NEW.invoice_toproject,
	plannedpoamt = NEW.plannedpoamt,
	lastplannedproposaldate = NEW.lastplannedproposaldate,
	document_copies = NEW.document_copies,
	accountno = NEW.accountno,
	expexpenses = NEW.expexpenses,
	expmargin = NEW.expmargin,
	expreinvoicing = NEW.expreinvoicing,
	responsible_id = NEW.responsible_id,
	servcost = NEW.servcost,
	servmargin = NEW.servmargin,
	servrevenue = NEW.servrevenue,
	setprojecttype = NEW.setprojecttype,
	startdate = NEW.startdate,
	a_asset_id = NEW.a_asset_id,
	schedulestatus = NEW.schedulestatus,
	actualcostamount = NEW.actualcostamount,
	percentdoneyet = NEW.percentdoneyet,
	estimatedamt = NEW.estimatedamt,
	qtyofproduct = NEW.qtyofproduct,
	m_product_id = NEW.m_product_id,
	closeproject = NEW.closeproject,
	materialcost = NEW.materialcost,
	indirectcost = NEW.indirectcost,
	machinecost = NEW.machinecost,
	expenses = NEW.expenses,
	reopenproject = NEW.reopenproject,
	isdefault=NEW.isdefault,
	isautotriggered  = new.isautotriggered  
WHERE
	c_project.c_project_id = NEW.c_project_id;

CREATE OR REPLACE RULE zssm_productionplan_v_delete AS
ON DELETE TO zssm_productionplan_v DO INSTEAD (
    DELETE FROM zssm_productionplan_task_v where zssm_productionplan_v_id = old.c_project_id;
    DELETE FROM zssm_productionplan_taskdep_v where zssm_productionplan_v_id = old.c_project_id;
    DELETE FROM c_project WHERE c_project.c_project_id = old.c_project_id;
);


CREATE OR REPLACE FUNCTION zssm_productionplan_task_trg ()
RETURNS TRIGGER AS
$body$
DECLARE
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT' or TG_OP = 'UPDATE') THEN
     update c_project set Projectstatus='OP' where c_project_id = NEW.c_project_id;
  end if;

  IF (TG_OP = 'INSERT') THEN
   IF (NEW.sortno IS NULL) THEN
    NEW.sortno := (SELECT COALESCE(MAX(sortno),0)+10 AS DefaultValue FROM zssm_productionplan_task ppws WHERE ppws.c_project_id = NEW.c_project_id);
   END IF;
  END IF;

  IF (TG_OP = 'DELETE') THEN
    update c_project set Projectstatus='OP' where c_project_id = old.c_project_id;
  END IF;

  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zssm_productionplan_task_trg', 'zssm_productionplan_task');
CREATE TRIGGER zssm_productionplan_task_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON zssm_productionplan_task FOR EACH ROW
  EXECUTE PROCEDURE zssm_productionplan_task_trg();

  
CREATE OR REPLACE FUNCTION zssm_productionplan_task_aft_trg ()
RETURNS TRIGGER AS
$body$
DECLARE
    v_cur record;
    v_depon varchar;
    v_seq numeric;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

    delete from zssm_productionplan_taskdep where c_project_id=new.c_project_id;
    if TG_OP != 'DELETE' then
        for v_cur in (select * from zssm_productionplan_task where c_project_id=new.c_project_id order by sortno) 
        LOOP
            if v_depon is not null then
                insert into zssm_productionplan_taskdep (zssm_productionplan_taskdep_id,createdby,updatedby,ad_client_id,ad_org_id,c_project_id,zssm_productionplan_task_id,dependsontask,sortno)
                values(get_uuid(),new.createdby,new.updatedby,new.ad_client_id,new.ad_org_id,new.c_project_id,v_cur.zssm_productionplan_task_id,v_depon,v_seq);
            end if;
            v_depon:=v_cur.zssm_productionplan_task_id;
            v_seq:=v_cur.sortno;
        END LOOP;
    end if;
  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zssm_productionplan_task_aft_trg', 'zssm_productionplan_task');
CREATE TRIGGER zssm_productionplan_task_aft_trg
  AFTER INSERT OR UPDATE 
  ON zssm_productionplan_task FOR EACH ROW
  EXECUTE PROCEDURE zssm_productionplan_task_aft_trg();
    

CREATE OR REPLACE FUNCTION zssm_productionplan_generate_trg ()
RETURNS TRIGGER AS
$body$
-- Generates a Simple Produktion Plan from a Workstep, if option isautogeneratedplan is choosen
-- Fires only on Insert or Update
DECLARE
    v_prj varchar;
    v_cur record;
    v_timpp numeric;
    v_settim numeric;
    v_i numeric;
    v_qty numeric;
    v_value varchar;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF; 
  if new.isautogeneratedplan='N' and new.isautotriggered='Y' then
    raise exception '%', '@zssm_taskOptionOnlyAutoGenerate@';
  end if;
  if new.isautogeneratedplan='Y' and new.c_project_id is null then
    if new.ad_org_id='0' then
        raise exception '%','@YouNeedToBeLoggedInWithOrganization@';
    end if;
    if (select count(*) from zssm_productionplan_task where c_projecttask_id=new.c_projecttask_id)=0 then
        select get_uuid() into v_prj;
        insert into c_project(c_project_id,createdby,updatedby,value,name,projectcategory,projectstatus,ad_client_id,ad_org_id,c_currency_id,timeperpiece,setuptime,isautotriggered,isdefault)
               values(v_prj,new.updatedby,new.updatedby,new.value,new.name,'PRP','OR',new.ad_client_id,new.ad_org_id,'102',new.timeperpiece,new.setuptime,new.isautotriggered,'Y');
        insert into zssm_productionplan_task(zssm_productionplan_task_id,c_project_id,c_projecttask_id,createdby,updatedby,sortno,ad_client_id,ad_org_id)
               values(get_uuid(),v_prj,new.c_projecttask_id,new.updatedby,new.updatedby,10,new.ad_client_id,new.ad_org_id);
        update  c_project set projectstatus='OR' where c_project_id=v_prj;
    else
        if (select count(*) from zssm_productionplan_task where c_projecttask_id=new.c_projecttask_id)=1 then
            select c_project_id into v_prj from zssm_productionplan_task where c_projecttask_id=new.c_projecttask_id;
            select sum(timeperpiece),sum(setuptime) into v_timpp,v_settim from c_projecttask where c_projecttask_id in (select c_projecttask_id from zssm_productionplan_task where c_project_id=v_prj and c_projecttask_id!=new.c_projecttask_id);
            update  c_project set timeperpiece=new.timeperpiece+coalesce(v_timpp,0),setuptime=new.setuptime+coalesce(v_settim,0),isautotriggered=new.isautotriggered  where c_project_id=v_prj;
        else
            raise exception '%', '@zssm_taskisinmultipleplansNoAutoGenerate@';
        end if;
    end if;
  else
    if TG_OP = 'UPDATE'  and new.c_project_id is null then
       if new.isautogeneratedplan='N' and old.isautogeneratedplan='Y' and (select count(*) from zssm_productionplan_task where c_projecttask_id=new.c_projecttask_id)=1 then
            select c_project_id into v_prj from zssm_productionplan_task where c_projecttask_id=new.c_projecttask_id;
            if (select count(*) from zssm_productionplan_task where c_project_id=v_prj)=1 then
                    delete from zssm_productionplan_task where c_project_id=v_prj;
                    delete from c_project where c_project_id=v_prj;
            end if;
       end if;
       if new.isautogeneratedplan='N' and old.timeperpiece!=new.timeperpiece or new.setuptime!=old.setuptime then
            -- invalidate all plans with this workstep
            for v_cur in (select c_project_id from zssm_productionplan_task where c_projecttask_id=new.c_projecttask_id)
            LOOP
                UPDATE c_project SET projectstatus = 'OP' where c_project_id=v_cur.c_project_id;
            END LOOP;
       end if;
    end if;
  end if;
  -- Auto Genetrate Serial Numbers on Production Orders
  IF c_getconfigoption('prefedineserials',new.ad_org_id)='Y' and (select count(*) from c_project where c_project_id=new.c_project_id and projectcategory='PRO')=1 then
    select value,qty into v_value,v_qty from c_projecttask where c_projecttask_id=new.c_projecttask_id;
    delete from zsmf_prefedineserials where zssm_workstep_v_id=new.c_projecttask_id;
    if (select count(*) from m_product where m_product_id=new.m_product_id and new.assembly='Y' and isserialtracking='Y')=1 then
        for v_i in 1..v_qty
        LOOP
            insert into zsmf_prefedineserials(zsmf_prefedineserials_id,zssm_workstep_v_id,AD_CLIENT_ID, AD_ORG_ID, CREATEDBY, UPDATEDBY,serialnumber)
                   values(get_uuid(),new.c_projecttask_id,'C726FEC915A54A0995C568555DA5BB3C',new.ad_org_id,new.CREATEDBY, new.UPDATEDBY,v_value||'-'||v_i);
        END LOOP;
    end if;
    if (select count(*) from m_product where m_product_id=new.m_product_id and new.assembly='Y' and isbatchtracking='Y')=1 then
        -- ToDo
    end if;
  end if;
  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zssm_productionplan_generate_trg', 'c_projecttask');
CREATE TRIGGER zssm_productionplan_generate_trg
  AFTER INSERT OR UPDATE 
  ON c_projecttask FOR EACH ROW
  EXECUTE PROCEDURE zssm_productionplan_generate_trg();



CREATE OR REPLACE FUNCTION zssm_taskdep_circle (
  p_projecttask_id VARCHAR,
  p_productionplan_task_id VARCHAR,
  p_tasklist VARCHAR[]
 )
RETURNS VOID
AS $body$
DECLARE
  j INTEGER := 0;
  v_contains BOOLEAN := FALSE;
  v_message  VARCHAR;
  cur_dependsontask RECORD;
  v_cmd VARCHAR;
  v_tasklist VARCHAR[]:=p_tasklist;
BEGIN
--  RAISE NOTICE '%', '';
--  RAISE NOTICE 'zssm_taskdep_circle(): ''%'', j=%', p_projecttask_id, j;

   -- Abbruchbedingung
    IF (isempty(v_tasklist[0])) THEN
   -- bei erstem Aufruf die beabsichtigte Beziehung in Liste ausgeben, noch nicht in DB wg. BEFORE INSERT
      v_tasklist[0] := p_projecttask_id;
   -- doppelter Schlüsselwert verletzt Unique-Constraint »zssm_productionplan_taskdep_key«
      IF ((SELECT COUNT(*) FROM zssm_productionplan_taskdep
           WHERE dependsontask = p_projecttask_id AND zssm_productionplan_task_id = p_productionplan_task_id) <> 0) THEN
        RAISE EXCEPTION '@zssm_relation_existent@';
      END IF;
    ELSE
      j := 0;
      LOOP
        IF (v_tasklist[j] IS NOT NULL) THEN
          IF (v_tasklist[j] = p_productionplan_task_id) THEN
            RAISE EXCEPTION '@zssm_relation_recursive@';
            RETURN;
          END IF;
        ELSE
          EXIT;
        END IF;
        j := j + 1;
      END LOOP;

    END IF;

    j := 0;
    FOR cur_dependsontask IN
    (
      SELECT tskdep.dependsontask FROM zssm_productionplan_taskdep tskdep WHERE tskdep.zssm_productionplan_task_id = p_projecttask_id
    )
    LOOP
     -- zur Liste hinzufuegen, wenn nicht vorhanden
   -- RAISE NOTICE ' Vorgaenger=% zu % pruefen', cur_dependsontask.dependsontask, p_projecttask_id; -- PRODUCTIONPLAN_TASK_D zu PRODUCTIONPLAN_TASK_E
      v_contains := FALSE;
      LOOP
        IF (v_tasklist[j] IS NOT NULL) THEN
          IF (v_tasklist[j] = cur_dependsontask.dependsontask) THEN -- PRODUCTIONPLAN_TASK_D
            v_contains := (v_tasklist[j] = cur_dependsontask.dependsontask);
            EXIT;
          END IF;
        ELSE
          EXIT;
        END IF;
        j := j + 1;
      END LOOP;

     -- Vorgaenger in Liste zufuegen
      IF (NOT v_contains) THEN
       IF (v_tasklist[j] IS NULL) THEN
     -- RAISE NOTICE ' fuege Vorgaenger hinzu: v_tasklist[%]= ''%'' ', j, cur_dependsontask.dependsontask; -- v_tasklist[%]=''%'''
        v_tasklist[j] := cur_dependsontask.dependsontask; -- 'PRODUCTIONPLAN_TASK_D', PRODUCTIONPLAN_TASK_G, PRODUCTIONPLAN_TASK_C, PRODUCTIONPLAN_TASK_A, PRODUCTIONPLAN_TASK_B
        PERFORM zssm_taskdep_circle(cur_dependsontask.dependsontask, p_productionplan_task_id, v_tasklist); -- suche Vorgaenger von PRODUCTIONPLAN_TASK_D, .. , PRODUCTIONPLAN_TASK_B
       END IF;
      END IF;

    END LOOP;
    RETURN;

END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssm_productionplan_taskdep_trg ()
RETURNS trigger AS
$body$
DECLARE
 v_projecttask_id VARCHAR;
 v_workstep_name VARCHAR;
 v_description VARCHAR;
 v_tasklist VARCHAR[];      -- dyn. erweiterbares Array
BEGIN
 BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE')  THEN
    update c_project set Projectstatus='OP' where c_project_id = NEW.c_project_id;
  END IF;

  IF (TG_OP = 'INSERT') THEN
    IF (NEW.sortno IS NULL) THEN
      NEW.sortno := (SELECT COALESCE(MAX(sortno),0)+10 AS DefaultValue FROM zssm_productionplan_taskdep ppwsl WHERE ppwsl.c_project_id = NEW.c_project_id);
    END IF;
 -- RAISE NOTICE '% (BEFORE INSERT): Vorgangsbeziehung von % zu % erstellen:', TG_NAME, NEW.dependsontask, NEW.zssm_productionplan_task_id;
    IF (isempty(NEW.dependsontask)) THEN
      RAISE EXCEPTION '@zssm_relation_dependsontask_required@';
    END IF;
    IF (isempty(NEW.zssm_productionplan_task_id)) THEN
      RAISE EXCEPTION '@zssm_relation_productionplan_task_required@';
    END IF;

    IF (NEW.dependsontask = NEW.zssm_productionplan_task_id) THEN
   -- RAISE NOTICE 'NEW.dependsontask=''%'', NEW.zssm_productionplan_task_id=''%''', NEW.dependsontask, NEW.zssm_productionplan_task_id;
      RAISE EXCEPTION '@zssm_relation_noSelfJoin@';
    END IF;

    PERFORM zssm_taskdep_circle(NEW.dependsontask, NEW.zssm_productionplan_task_id, v_tasklist);
 -- RAISE NOTICE '% (BEFORE INSERT): Vorgangsbeziehung von % zu % erstellt', TG_NAME, NEW.dependsontask, NEW.zssm_productionplan_task_id;
   -- nur zur Programmentwicklung - Feld 'zssm_productionplan_taskdep.description' kann später wieder entfernt werden - MH 19.10.12
    v_projecttask_id := (SELECT ppws.c_projecttask_id FROM zssm_productionplan_task ppws WHERE ppws.zssm_productionplan_task_id = NEW.dependsontask);
    v_workstep_name := COALESCE((SELECT wsv.name FROM zssm_workstep_v wsv WHERE wsv.c_projecttask_id = v_projecttask_id), 'NEW.dependsontask ?');
    v_description := substring(v_workstep_name, 1, 58);

    v_projecttask_id := (SELECT ppws.c_projecttask_id FROM zssm_productionplan_task ppws WHERE ppws.zssm_productionplan_task_id = NEW.zssm_productionplan_task_id);
    v_workstep_name := COALESCE((SELECT wsv.name FROM zssm_workstep_v wsv WHERE wsv.c_projecttask_id = v_projecttask_id), 'NEW.zssm_productionplan_task_id ?');
    v_description := v_description || ' - ' || substring(v_workstep_name, 1, 58);
    
  END IF;

  IF (TG_OP = 'DELETE')  THEN
    update c_project set Projectstatus='OP' where c_project_id = old.c_project_id;
  END IF;

  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
 END;
EXCEPTION
WHEN OTHERS THEN
  RAISE EXCEPTION '%', SQLERRM;
  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zssm_productionplan_taskdep_trg', 'zssm_productionplan_taskdep');
CREATE TRIGGER zssm_productionplan_taskdep_trg
  BEFORE INSERT OR UPDATE OR DELETE
  ON zssm_productionplan_taskdep FOR EACH ROW
  EXECUTE PROCEDURE zssm_productionplan_taskdep_trg();


SELECT zsse_DropView ('zssm_productionorder_v');
CREATE OR REPLACE VIEW zssm_productionorder_v AS
SELECT
	c_project.c_project_id AS zssm_productionorder_v_id,
	c_project.c_project_id AS c_project_id,
	c_project.ad_client_id AS ad_client_id,
	c_project.ad_org_id AS ad_org_id,
	c_project.isactive AS isactive,
	c_project.created AS created,
	c_project.createdby AS createdby,
	c_project.updated AS updated,
	c_project.updatedby AS updatedby,
	c_project.value AS value,
	c_project.name AS name,
	c_project.description AS description,
	c_project.note AS note,
	c_project.issummary AS issummary,
	c_project.ad_user_id AS ad_user_id,
	c_project.c_bpartner_id AS c_bpartner_id,
	c_project.c_bpartner_location_id AS c_bpartner_location_id,
	c_project.poreference AS poreference,
	c_project.c_paymentterm_id AS c_paymentterm_id,
	c_project.c_currency_id AS c_currency_id,
	c_project.createtemppricelist AS createtemppricelist,
	c_project.m_pricelist_version_id AS m_pricelist_version_id,
	c_project.c_campaign_id AS c_campaign_id,
	c_project.iscommitment AS iscommitment,
	c_project.plannedamt AS plannedamt,
	c_project.plannedqty AS plannedqty,
	c_project.plannedmarginamt AS plannedmarginamt,
	c_project.committedamt AS committedamt,
	c_project.datecontract AS datecontract,
	c_project.datefinish AS datefinish,
	c_project.generateto AS generateto,
	c_project.processed AS processed,
	c_project.salesrep_id AS salesrep_id,
	c_project.copyfrom AS copyfrom,
	c_project.c_projecttype_id AS c_projecttype_id,
	c_project.committedqty AS committedqty,
	c_project.invoicedamt AS invoicedamt,
	c_project.invoicedqty AS invoicedqty,
	c_project.projectbalanceamt AS projectbalanceamt,
	c_project.c_phase_id AS c_phase_id,
	c_project.iscommitceiling AS iscommitceiling,
	c_project.m_warehouse_id AS m_warehouse_id,
	c_project.projectcategory AS projectcategory,
	c_project.processing AS processing,
	c_project.publicprivate AS publicprivate,
	c_project.projectstatus AS projectstatus,
	c_project.projectkind AS projectkind,
	c_project.billto_id AS billto_id,
	c_project.projectphase AS projectphase,
	c_project.generateorder AS generateorder,
	c_project.changeprojectstatus AS changeprojectstatus,
	c_project.c_location_id AS c_location_id,
	c_project.m_pricelist_id AS m_pricelist_id,
	c_project.paymentrule AS paymentrule,
	c_project.invoice_toproject AS invoice_toproject,
	c_project.plannedpoamt AS plannedpoamt,
	c_project.lastplannedproposaldate AS lastplannedproposaldate,
	c_project.document_copies AS document_copies,
	c_project.accountno AS accountno,
	c_project.expexpenses AS expexpenses,
	c_project.expmargin AS expmargin,
	c_project.expreinvoicing AS expreinvoicing,
	c_project.responsible_id AS responsible_id,
	c_project.servcost AS servcost,
	c_project.servmargin AS servmargin,
	c_project.servrevenue AS servrevenue,
	c_project.setprojecttype AS setprojecttype,
	c_project.startdate AS startdate,
	c_project.a_asset_id AS a_asset_id,
	c_project.schedulestatus AS schedulestatus,
	c_project.actualcostamount AS actualcostamount,
	c_project.percentdoneyet AS percentdoneyet,
	c_project.estimatedamt AS estimatedamt,
	c_project.qtyofproduct AS qtyofproduct,
	c_project.m_product_id AS m_product_id,
	c_project.closeproject AS closeproject,
	c_project.materialcost AS materialcost,
	c_project.indirectcost AS indirectcost,
	c_project.machinecost AS machinecost,
	c_project.expenses AS expenses,
	c_project.reopenproject AS reopenproject,
	c_project.isapproved,
  c_project.prpreference
FROM c_project
WHERE c_project.projectcategory = 'PRO';

CREATE OR REPLACE RULE zssm_productionorder_v_insert AS
ON INSERT TO zssm_productionorder_v DO INSTEAD
INSERT INTO c_project (
	c_project_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	value,
	name,
	description,
	note,
	issummary,
	ad_user_id,
	c_bpartner_id,
	c_bpartner_location_id,
	poreference,
	c_paymentterm_id,
	c_currency_id,
	createtemppricelist,
	m_pricelist_version_id,
	c_campaign_id,
	iscommitment,
	plannedamt,
	plannedqty,
	plannedmarginamt,
	committedamt,
	datecontract,
	datefinish,
	generateto,
	processed,
	salesrep_id,
	copyfrom,
	c_projecttype_id,
	committedqty,
	invoicedamt,
	invoicedqty,
	projectbalanceamt,
	c_phase_id,
	iscommitceiling,
	m_warehouse_id,
	projectcategory,
	processing,
	publicprivate,
	projectstatus,
	projectkind,
	billto_id,
	projectphase,
	generateorder,
	changeprojectstatus,
	c_location_id,
	m_pricelist_id,
	paymentrule,
	invoice_toproject,
	plannedpoamt,
	lastplannedproposaldate,
	document_copies,
	accountno,
	expexpenses,
	expmargin,
	expreinvoicing,
	responsible_id,
	servcost,
	servmargin,
	servrevenue,
	setprojecttype,
	startdate,
	a_asset_id,
	schedulestatus,
	actualcostamount,
	percentdoneyet,
	estimatedamt,
	qtyofproduct,
	m_product_id,
	closeproject,
	materialcost,
	indirectcost,
	machinecost,
	expenses,
	reopenproject,
  prpreference,isapproved
  )
 VALUES (
	NEW.zssm_productionorder_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
	COALESCE(NEW.isactive, 'Y'),
	COALESCE(NEW.created, now()),
	NEW.createdby,
	COALESCE(NEW.updated, now()),
	NEW.updatedby,
	NEW.value,
	NEW.name,
	NEW.description,
	NEW.note,
	COALESCE(NEW.issummary, 'N'),
	NEW.ad_user_id,
	NEW.c_bpartner_id,
	NEW.c_bpartner_location_id,
	NEW.poreference,
	NEW.c_paymentterm_id,
	NEW.c_currency_id,
	COALESCE(NEW.createtemppricelist,'Y'),
	NEW.m_pricelist_version_id,
	NEW.c_campaign_id,
	COALESCE(NEW.iscommitment, 'Y'),
	COALESCE(NEW.plannedamt, 0),
	COALESCE(NEW.plannedqty, 0),
	COALESCE(NEW.plannedmarginamt, 0),
	COALESCE(NEW.committedamt, 0),
	NEW.datecontract,
	NEW.datefinish,
	NEW.generateto,
	COALESCE(NEW.processed, 'N'),
	NEW.salesrep_id,
	NEW.copyfrom,
	NEW.c_projecttype_id,
	COALESCE(NEW.committedqty, 0),
	COALESCE(NEW.invoicedamt, 0),
	COALESCE(NEW.invoicedqty, 0),
	COALESCE(NEW.projectbalanceamt, 0),
	NEW.c_phase_id,
	COALESCE(NEW.iscommitceiling, 'N'),
	NEW.m_warehouse_id,
	COALESCE(NEW.projectcategory, 'PRO'),
	NEW.processing,
	NEW.publicprivate,
	NEW.projectstatus,
	NEW.projectkind,
	NEW.billto_id,
	NEW.projectphase,
	COALESCE(NEW.generateorder, 'N'),
	COALESCE(NEW.changeprojectstatus, 'N'),
	NEW.c_location_id,
	NEW.m_pricelist_id,
	NEW.paymentrule,
	COALESCE(NEW.invoice_toproject, 'N'),
	COALESCE(NEW.plannedpoamt, 0),
	NEW.lastplannedproposaldate,
	NEW.document_copies,
	NEW.accountno,
	NEW.expexpenses,
	NEW.expmargin,
	NEW.expreinvoicing,
	NEW.responsible_id,
	NEW.servcost,
	NEW.servmargin,
	NEW.servrevenue,
	NEW.setprojecttype,
	NEW.startdate,
	NEW.a_asset_id,
	COALESCE(NEW.schedulestatus, 'OK'),
	NEW.actualcostamount,
	NEW.percentdoneyet,
	NEW.estimatedamt,
	NEW.qtyofproduct,
	NEW.m_product_id,
	COALESCE(NEW.closeproject, 'N'),
	NEW.materialcost,
	NEW.indirectcost,
	NEW.machinecost,
	NEW.expenses,
	COALESCE(NEW.reopenproject, 'N'),
  NEW.prpreference,new.isapproved);

CREATE OR REPLACE RULE zssm_productionorder_v_update AS
ON UPDATE TO zssm_productionorder_v DO INSTEAD
UPDATE c_project SET
	c_project_id = NEW.zssm_productionorder_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	value = NEW.value,
	name = NEW.name,
	description = NEW.description,
	note = NEW.note,
	issummary = NEW.issummary,
	ad_user_id = NEW.ad_user_id,
	c_bpartner_id = NEW.c_bpartner_id,
	c_bpartner_location_id = NEW.c_bpartner_location_id,
	poreference = NEW.poreference,
	c_paymentterm_id = NEW.c_paymentterm_id,
	c_currency_id = NEW.c_currency_id,
	createtemppricelist = NEW.createtemppricelist,
	m_pricelist_version_id = NEW.m_pricelist_version_id,
	c_campaign_id = NEW.c_campaign_id,
	iscommitment = NEW.iscommitment,
	plannedamt = NEW.plannedamt,
	plannedqty = NEW.plannedqty,
	plannedmarginamt = NEW.plannedmarginamt,
	committedamt = NEW.committedamt,
	datecontract = NEW.datecontract,
	datefinish = NEW.datefinish,
	generateto = NEW.generateto,
	processed = NEW.processed,
	salesrep_id = NEW.salesrep_id,
	copyfrom = NEW.copyfrom,
	c_projecttype_id = NEW.c_projecttype_id,
	committedqty = NEW.committedqty,
	invoicedamt = NEW.invoicedamt,
	invoicedqty = NEW.invoicedqty,
	projectbalanceamt = NEW.projectbalanceamt,
	c_phase_id = NEW.c_phase_id,
	iscommitceiling = NEW.iscommitceiling,
	m_warehouse_id = NEW.m_warehouse_id,
	projectcategory = NEW.projectcategory,
	processing = NEW.processing,
	publicprivate = NEW.publicprivate,
	projectstatus = NEW.projectstatus,
	projectkind = NEW.projectkind,
	billto_id = NEW.billto_id,
	projectphase = NEW.projectphase,
	generateorder = NEW.generateorder,
	changeprojectstatus = NEW.changeprojectstatus,
	c_location_id = NEW.c_location_id,
	m_pricelist_id = NEW.m_pricelist_id,
	paymentrule = NEW.paymentrule,
	invoice_toproject = NEW.invoice_toproject,
	plannedpoamt = NEW.plannedpoamt,
	lastplannedproposaldate = NEW.lastplannedproposaldate,
	document_copies = NEW.document_copies,
	accountno = NEW.accountno,
	expexpenses = NEW.expexpenses,
	expmargin = NEW.expmargin,
	expreinvoicing = NEW.expreinvoicing,
	responsible_id = NEW.responsible_id,
	servcost = NEW.servcost,
	servmargin = NEW.servmargin,
	servrevenue = NEW.servrevenue,
	setprojecttype = NEW.setprojecttype,
	startdate = NEW.startdate,
	a_asset_id = NEW.a_asset_id,
	schedulestatus = NEW.schedulestatus,
	actualcostamount = NEW.actualcostamount,
	percentdoneyet = NEW.percentdoneyet,
	estimatedamt = NEW.estimatedamt,
	qtyofproduct = NEW.qtyofproduct,
	m_product_id = NEW.m_product_id,
	closeproject = NEW.closeproject,
	materialcost = NEW.materialcost,
	indirectcost = NEW.indirectcost,
	machinecost = NEW.machinecost,
	expenses = NEW.expenses,
	reopenproject = NEW.reopenproject,
  prpreference = NEW.prpreference,
  isapproved=new.isapproved
WHERE
	c_project.c_project_id = NEW.c_project_id;

CREATE OR REPLACE FUNCTION zssm_delete_workstep_v (
  p_zssm_productionOrder_v_id VARCHAR  -- delete c_project.c_project_id, id production
 )
/*
 delete all depending records on zssm_productionorder_v (=c_projekt):
 - all zspm_projecttaskdep
 - all zspm_projecttaskbom
 - all zspm_ptaskhrplan
 - all zspm_ptaskmachineplan
 - all zssm_workstep_v (=c_projecttask),
*/
RETURNS VARCHAR -- '@Success@'
AS $body$
 -- SELECT zssm_delete_workstep_v('379397F12A65499DAB5BDD0B61EA41E4');
 -- this function is excecuted within DELETE-rule: zssm_productionorder_v_delete ON zssm_workstep_v
DECLARE
  v_message VARCHAR;
  cur_prp_workstep RECORD;
BEGIN
--RAISE NOTICE 'zssm_delete_workstep_v(p_zssm_productionOrder_v_id)= %', p_zssm_productionOrder_v_id;
  IF (zspm_isProductionOrder(p_zssm_productionOrder_v_id)) THEN
    FOR cur_prp_workstep IN
   -- (SELECT wsv.zssm_workstep_v_id FROM zssm_workstep_v wsv WHERE wsv.c_project_id = p_zssm_productionOrder_v_id)
      (SELECT wsv.zssm_workstep_v_id FROM zssm_workstep_v wsv WHERE wsv.zssm_productionorder_v_id = p_zssm_productionOrder_v_id) -- 02.01.12
    LOOP
      RAISE NOTICE '  DELETE zssm_workstep_v.zssm_workstep_v_id = %', cur_prp_workstep.zssm_workstep_v_id;
      DELETE FROM zspm_projecttaskdep dep WHERE dep.dependsontask = cur_prp_workstep.zssm_workstep_v_id;
      DELETE FROM zspm_projecttaskdep dep WHERE dep.c_projecttask_id = cur_prp_workstep.zssm_workstep_v_id;
      DELETE FROM zspm_projecttaskbom bom WHERE bom.c_projecttask_id = cur_prp_workstep.zssm_workstep_v_id; -- zspm_projecttaskbom_trg @zspm_NoChangeMatdisposed@
      DELETE FROM zspm_ptaskhrplan hrplan WHERE hrplan.c_projecttask_id = cur_prp_workstep.zssm_workstep_v_id;
      DELETE FROM zspm_ptaskmachineplan mchplan WHERE mchplan.c_projecttask_id = cur_prp_workstep.zssm_workstep_v_id;
      DELETE FROM zssm_ptasktechdoc techdoc WHERE techdoc.c_projecttask_id = cur_prp_workstep.zssm_workstep_v_id;
      DELETE FROM zssm_workstep_v wsv WHERE wsv.zssm_workstep_v_id = cur_prp_workstep.zssm_workstep_v_id;
    END LOOP;
    v_message := '@Success@ ' || '@zssm_delete_workstep_v@';
    RETURN v_message;
  ELSE
    v_message := 'INFORMATION ' || '@zssm_ProductionOrderNotFound@';
    RAISE NOTICE '% zssm_delete_workstep_v(p_zssm_productionOrder_v_id)= %', v_message, p_zssm_productionOrder_v_id;
    RETURN v_message;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    v_message := '@Error@ zssm_delete_workstep_v:' || SQLERRM;
    RAISE EXCEPTION '%', v_message;
    RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE RULE zssm_productionorder_v_delete AS ON DELETE TO public.zssm_productionorder_v
DO INSTEAD (
 SELECT zssm_delete_workstep_v(old.c_project_id) AS zssm_delete_workstep_v;
 DELETE FROM c_project
  WHERE c_project.c_project_id::text = old.c_project_id::text;
);



SELECT zsse_DropView ('zssm_workstepdependencies_v');
CREATE OR REPLACE VIEW zssm_workstepdependencies_v AS
SELECT
	zspm_projecttaskdep.zspm_projecttaskdep_id AS zssm_workstepdependencies_v_id,
	zspm_projecttaskdep.zspm_projecttaskdep_id AS zspm_projecttaskdep_id,
	zspm_projecttaskdep.ad_client_id AS ad_client_id,
	zspm_projecttaskdep.ad_org_id AS ad_org_id,
	zspm_projecttaskdep.isactive AS isactive,
	zspm_projecttaskdep.created AS created,
	zspm_projecttaskdep.createdby AS createdby,
	zspm_projecttaskdep.updated AS updated,
	zspm_projecttaskdep.updatedby AS updatedby,
	zspm_projecttaskdep.c_projecttask_id AS zssm_workstep_v_id,
	zspm_projecttaskdep.dependsontask AS dependsontask
FROM zspm_projecttaskdep;

CREATE OR REPLACE RULE zssm_workstepdependencies_v_insert AS
ON INSERT TO zssm_workstepdependencies_v DO INSTEAD
INSERT INTO zspm_projecttaskdep (
	zspm_projecttaskdep_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	c_projecttask_id,
	dependsontask
) VALUES (
	NEW.zssm_workstepdependencies_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
	NEW.isactive,
	NEW.created,
	NEW.createdby,
	NEW.updated,
	NEW.updatedby,
	NEW.zssm_workstep_v_id,
	NEW.dependsontask);

CREATE OR REPLACE RULE zssm_workstepdependencies_v_update AS
ON UPDATE TO zssm_workstepdependencies_v DO INSTEAD
UPDATE zspm_projecttaskdep SET
	zspm_projecttaskdep_id = NEW.zssm_workstepdependencies_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	c_projecttask_id = NEW.zssm_workstep_v_id,
	dependsontask = NEW.dependsontask
WHERE
	zspm_projecttaskdep.zspm_projecttaskdep_id = NEW.zspm_projecttaskdep_id;

CREATE OR REPLACE RULE zssm_workstepdependencies_v_delete AS
ON DELETE TO zssm_workstepdependencies_v DO INSTEAD
DELETE FROM zspm_projecttaskdep WHERE
	zspm_projecttaskdep.zspm_projecttaskdep_id = old.zspm_projecttaskdep_id;

SELECT zsse_DropView ('zssm_workstepactivities_v');
CREATE OR REPLACE VIEW zssm_workstepactivities_v AS
SELECT
	zspm_ptaskhrplan.zspm_ptaskhrplan_id AS zssm_workstepactivities_v_id,
	zspm_ptaskhrplan.zspm_ptaskhrplan_id AS zspm_ptaskhrplan_id,
	zspm_ptaskhrplan.ad_client_id AS ad_client_id,
	zspm_ptaskhrplan.ad_org_id AS ad_org_id,
	zspm_ptaskhrplan.c_projecttask_id AS zssm_workstep_v_id,
	zspm_ptaskhrplan.c_projecttask_id AS zssm_workstep_prp_v_id,
	zspm_ptaskhrplan.isactive AS isactive,
	zspm_ptaskhrplan.created AS created,
	zspm_ptaskhrplan.createdby AS createdby,
	zspm_ptaskhrplan.updated AS updated,
	zspm_ptaskhrplan.updatedby AS updatedby,
	zspm_ptaskhrplan.c_salary_category_id AS c_salary_category_id,
	zspm_ptaskhrplan.quantity AS quantity,
	zspm_ptaskhrplan.planned_quantity AS planned_quantity,
	zspm_ptaskhrplan.costuom AS costuom,
	zspm_ptaskhrplan.averageduration AS averageduration,
	zspm_ptaskhrplan.planned_averageduration AS planned_averageduration,
	zspm_ptaskhrplan.durationunit AS durationunit,
	zspm_ptaskhrplan.planned_durationunit AS planned_durationunit,
	zspm_ptaskhrplan.zssm_section_id AS zssm_section_id,
	zspm_ptaskhrplan.employee_id as employee_id,
	zspm_ptaskhrplan.datefrom as datefrom,
	zspm_ptaskhrplan.dateto as dateto,
	zspm_ptaskhrplan.specification as specification,
	zspm_ptaskhrplan.shift as shift
	
FROM zspm_ptaskhrplan;

CREATE OR REPLACE RULE zssm_workstepactivities_v_insert AS
ON INSERT TO zssm_workstepactivities_v DO INSTEAD
INSERT INTO zspm_ptaskhrplan (
	zspm_ptaskhrplan_id,
	ad_client_id,
	ad_org_id,
	c_projecttask_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	c_salary_category_id,
	quantity,
	costuom,
	averageduration,
	durationunit,
	zssm_section_id,
	employee_id,
	datefrom,
	dateto,
	specification,
	shift
) VALUES (
	NEW.zssm_workstepactivities_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
	coalesce(NEW.zssm_workstep_v_id,NEW.zssm_workstep_prp_v_id),
	NEW.isactive,
	NEW.created,
	NEW.createdby,
	NEW.updated,
	NEW.updatedby,
	NEW.c_salary_category_id,
	NEW.quantity,
	NEW.costuom,
	NEW.averageduration,
	NEW.durationunit,
	NEW.zssm_section_id,
	NEW.employee_id,
	NEW.datefrom,
	NEW.dateto,
	NEW.specification,
	NEW.shift);

CREATE OR REPLACE RULE zssm_workstepactivities_v_update AS
ON UPDATE TO zssm_workstepactivities_v DO INSTEAD
UPDATE zspm_ptaskhrplan SET
	zspm_ptaskhrplan_id = NEW.zssm_workstepactivities_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	c_projecttask_id = NEW.zssm_workstep_v_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	c_salary_category_id = NEW.c_salary_category_id,
	quantity = NEW.quantity,
	costuom = NEW.costuom,
	averageduration = NEW.averageduration,
	durationunit = NEW.durationunit,
	zssm_section_id = NEW.zssm_section_id,
	employee_id=NEW.employee_id,
	datefrom=NEW.datefrom,
	dateto=NEW.dateto,
	specification=NEW.specification,
	shift=NEW.shift
WHERE
	zspm_ptaskhrplan.zspm_ptaskhrplan_id = NEW.zspm_ptaskhrplan_id;

CREATE OR REPLACE RULE zssm_workstepactivities_v_delete AS
ON DELETE TO zssm_workstepactivities_v DO INSTEAD
DELETE FROM zspm_ptaskhrplan WHERE
	zspm_ptaskhrplan.zspm_ptaskhrplan_id = old.zspm_ptaskhrplan_id;

SELECT zsse_DropView ('zssm_workstepmachines_v');
CREATE OR REPLACE VIEW zssm_workstepmachines_v AS
SELECT
	zspm_ptaskmachineplan.zspm_ptaskmachineplan_id AS zssm_workstepmachines_v_id,
	zspm_ptaskmachineplan.zspm_ptaskmachineplan_id AS zspm_ptaskmachineplan_id,
	zspm_ptaskmachineplan.ad_client_id AS ad_client_id,
	zspm_ptaskmachineplan.ad_org_id AS ad_org_id,
	zspm_ptaskmachineplan.c_projecttask_id AS zssm_workstep_v_id,
	zspm_ptaskmachineplan.c_projecttask_id AS zssm_workstep_prp_v_id,
	zspm_ptaskmachineplan.isactive AS isactive,
	zspm_ptaskmachineplan.created AS created,
	zspm_ptaskmachineplan.createdby AS createdby,
	zspm_ptaskmachineplan.updated AS updated,
	zspm_ptaskmachineplan.updatedby AS updatedby,
	zspm_ptaskmachineplan.ma_machine_id AS ma_machine_id,
	zspm_ptaskmachineplan.quantity AS quantity,
	zspm_ptaskmachineplan.costuom AS costuom,
	zspm_ptaskmachineplan.averageduration AS averageduration,
	zspm_ptaskmachineplan.durationunit AS durationunit,
	zspm_ptaskmachineplan.zssm_section_id AS zssm_section_id,
	zspm_ptaskmachineplan.datefrom AS datefrom,
	zspm_ptaskmachineplan.dateto AS dateto
FROM zspm_ptaskmachineplan;

CREATE OR REPLACE RULE zssm_workstepmachines_v_insert AS
ON INSERT TO zssm_workstepmachines_v DO INSTEAD
INSERT INTO zspm_ptaskmachineplan (
	zspm_ptaskmachineplan_id,
	ad_client_id,
	ad_org_id,
	c_projecttask_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	ma_machine_id,
	quantity,
	costuom,
	averageduration,
	durationunit,
	zssm_section_id,
	datefrom,
	dateto
) VALUES (
	NEW.zssm_workstepmachines_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
	coalesce(NEW.zssm_workstep_v_id,NEW.zssm_workstep_prp_v_id),
	NEW.isactive,
	NEW.created,
	NEW.createdby,
	NEW.updated,
	NEW.updatedby,
	NEW.ma_machine_id,
	NEW.quantity,
	NEW.costuom,
	NEW.averageduration,
	NEW.durationunit,
	NEW.zssm_section_id,
	NEW.datefrom,
	NEW.dateto);

CREATE OR REPLACE RULE zssm_workstepmachines_v_update AS
ON UPDATE TO zssm_workstepmachines_v DO INSTEAD
UPDATE zspm_ptaskmachineplan SET
	zspm_ptaskmachineplan_id = NEW.zssm_workstepmachines_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	c_projecttask_id = NEW.zssm_workstep_v_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	ma_machine_id = NEW.ma_machine_id,
	quantity = NEW.quantity,
	costuom = NEW.costuom,
	averageduration = NEW.averageduration,
	durationunit = NEW.durationunit,
	zssm_section_id = NEW.zssm_section_id,
	datefrom = NEW.datefrom,
	dateto = NEW.dateto
WHERE
	zspm_ptaskmachineplan.zspm_ptaskmachineplan_id = NEW.zspm_ptaskmachineplan_id;

CREATE OR REPLACE RULE zssm_workstepmachines_v_delete AS
ON DELETE TO zssm_workstepmachines_v DO INSTEAD
DELETE FROM zspm_ptaskmachineplan WHERE
	zspm_ptaskmachineplan.zspm_ptaskmachineplan_id = old.zspm_ptaskmachineplan_id;

SELECT zsse_DropView ('zssm_workstepbom_v');
CREATE OR REPLACE VIEW zssm_workstepbom_v AS
SELECT
	zspm_projecttaskbom.zspm_projecttaskbom_id AS zssm_workstepbom_v_id,
	zspm_projecttaskbom.c_projecttask_id AS zssm_workstep_prp_v_id,
	zspm_projecttaskbom.zspm_projecttaskbom_id AS zspm_projecttaskbom_id,
	zspm_projecttaskbom.c_projecttask_id AS zssm_workstep_v_id,
	zspm_projecttaskbom.ad_client_id AS ad_client_id,
	zspm_projecttaskbom.ad_org_id AS ad_org_id,
	zspm_projecttaskbom.isactive AS isactive,
	zspm_projecttaskbom.created AS created,
	zspm_projecttaskbom.createdby AS createdby,
	zspm_projecttaskbom.updated AS updated,
	zspm_projecttaskbom.updatedby AS updatedby,
	zspm_projecttaskbom.m_product_id AS m_product_id,
	zspm_projecttaskbom.quantity AS quantity,
	zspm_projecttaskbom.m_locator_id AS m_locator_id,
	zspm_projecttaskbom.description AS description,
	zspm_projecttaskbom.actualcosamount AS actualcosamount,
	zspm_projecttaskbom.constuctivemeasure AS constuctivemeasure,
	zspm_projecttaskbom.rawmaterial AS rawmaterial,
	zspm_projecttaskbom.cutoff AS cutoff,
	zspm_projecttaskbom.qty_plan AS qty_plan,
	zspm_projecttaskbom.qtyreserved AS qtyreserved,
	zspm_projecttaskbom.qtyinrequisition AS qtyinrequisition,
	zspm_projecttaskbom.qtyreceived AS qtyreceived,
	zspm_projecttaskbom.date_plan AS date_plan,
	zspm_projecttaskbom.planrequisition AS planrequisition,
	zspm_projecttaskbom.issuing_locator AS issuing_locator,
	zspm_projecttaskbom.receiving_locator AS receiving_locator,
	zspm_projecttaskbom.line as line,
	case when t.assembly='N' and p.projectcategory = 'PRO' then null else
	case when coalesce(p.projectstatus,'nix') = 'OR' and zspm_projecttaskbom.receiving_locator is not null then
            M_Qty_AvailableInTime(zspm_projecttaskbom.m_product_id,(select m_warehouse_id from m_locator 
                    where m_locator_id=zspm_projecttaskbom.receiving_locator),zspm_projecttaskbom.date_plan) + (zspm_projecttaskbom.quantity-zspm_projecttaskbom.qtyreceived) 
        else
            M_Qty_AvailableInTime(zspm_projecttaskbom.m_product_id,(select m_warehouse_id from m_locator 
                    where m_locator_id=zspm_projecttaskbom.receiving_locator),zspm_projecttaskbom.date_plan)
        end
    end
    as qty_available,
    m_bom_qty_onhand(zspm_projecttaskbom.m_product_id,null,zspm_projecttaskbom.receiving_locator) AS  qty_instock,
    zspm_projecttaskbom.snr_batchmasterdata_id
FROM zspm_projecttaskbom,c_projecttask t left join  c_project p on t.c_project_id=p.c_project_id
WHERE zspm_projecttaskbom.c_projecttask_id=t.c_projecttask_id;

CREATE OR REPLACE RULE zssm_workstepbom_v_insert AS
ON INSERT TO zssm_workstepbom_v DO INSTEAD
INSERT INTO zspm_projecttaskbom (
	zspm_projecttaskbom_id,
	c_projecttask_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	m_product_id,
	quantity,
	m_locator_id,
	description,
	actualcosamount,
	constuctivemeasure,
	rawmaterial,
	cutoff,
	qty_plan,
	qtyreserved,
	qtyinrequisition,
	qtyreceived,
	date_plan,
	planrequisition,
	issuing_locator,
	receiving_locator,
	line,
	snr_batchmasterdata_id
) VALUES (
	NEW.zssm_workstepbom_v_id,
	coalesce(NEW.zssm_workstep_v_id,NEW.zssm_workstep_prp_v_id),
	NEW.ad_client_id,
	NEW.ad_org_id,
	NEW.isactive,
	NEW.created,
	NEW.createdby,
	NEW.updated,
	NEW.updatedby,
	NEW.m_product_id,
	NEW.quantity,
	NEW.m_locator_id,
	NEW.description,
	NEW.actualcosamount,
	NEW.constuctivemeasure,
	NEW.rawmaterial,
	NEW.cutoff,
	NEW.qty_plan,
	NEW.qtyreserved,
	NEW.qtyinrequisition,
	NEW.qtyreceived,
	NEW.date_plan,
	NEW.planrequisition,
	NEW.issuing_locator,
	NEW.receiving_locator,
	new.line,
	new.snr_batchmasterdata_id);

CREATE OR REPLACE RULE zssm_workstepbom_v_update AS
ON UPDATE TO zssm_workstepbom_v DO INSTEAD
UPDATE zspm_projecttaskbom SET
	zspm_projecttaskbom_id = NEW.zssm_workstepbom_v_id,
	c_projecttask_id = NEW.zssm_workstep_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	m_product_id = NEW.m_product_id,
	quantity = NEW.quantity,
	m_locator_id = NEW.m_locator_id,
	description = NEW.description,
	actualcosamount = NEW.actualcosamount,
	constuctivemeasure = NEW.constuctivemeasure,
	rawmaterial = NEW.rawmaterial,
	cutoff = NEW.cutoff,
	qty_plan = NEW.qty_plan,
	qtyreserved = NEW.qtyreserved,
	qtyinrequisition = NEW.qtyinrequisition,
	qtyreceived = NEW.qtyreceived,
	date_plan = NEW.date_plan,
	planrequisition = NEW.planrequisition,
	issuing_locator = NEW.issuing_locator,
	receiving_locator = NEW.receiving_locator,
	line=new.line,
	snr_batchmasterdata_id=new.snr_batchmasterdata_id
WHERE
	zspm_projecttaskbom.zspm_projecttaskbom_id = NEW.zspm_projecttaskbom_id;

CREATE OR REPLACE RULE zssm_workstepbom_v_delete AS
ON DELETE TO zssm_workstepbom_v DO INSTEAD
DELETE FROM zspm_projecttaskbom WHERE
	zspm_projecttaskbom.zspm_projecttaskbom_id = old.zspm_projecttaskbom_id;


CREATE OR REPLACE FUNCTION zssm_is_material_complete (
  p_projecttask_id VARCHAR
 )
RETURNS BOOLEAN
AS $body$
/*
  Gegenueberstellung der Plan-Mengen mit den Mengen der Materialbewegungen
  und den verfuegbaren Bestaenden im Entnahme-Lagerort.
  Entspricht sie Summe der Materialbewegungen (und bei Unterdeckung eine zus. verfuegbare Lagermenge)
  der Plan-Menge, ist ist die Pruefung erfolgreich
*/
-- SELECT zssm_is_material_complete('7F1A591D8AC848F98B50297B2E786244');
-- SELECT zssm_is_material_complete('7F1A591D8AC848F98B50297B2E7862'); -- @zssm_projecttaskbomNotFound@
DECLARE
  result     BOOLEAN := FALSE;
  v_message  VARCHAR;
  cur_projecttaskbom   RECORD;

  v_projecttask_id     VARCHAR;
  v_ic_projecttask_id  VARCHAR;
  v_ic_product_id      VARCHAR;
  v_ic_sum_movementqty NUMERIC;

  v_req_stock_qty      NUMERIC := 0;
  v_sd_qtyonhand       NUMERIC;
BEGIN
  BEGIN
  SELECT wsv.c_projecttask_id FROM zssm_workstep_v wsv INTO v_projecttask_id WHERE wsv.c_projecttask_id = p_projecttask_id;
    IF (NOT isempty(v_projecttask_id)) THEN -- Datensatz gefunden v_projecttask.c_projecttask_id
      FOR cur_projecttaskbom IN (
        SELECT ptbom.c_projecttask_id, ptbom.m_product_id, ptbom.receiving_locator, sum(COALESCE(ptbom.quantity, 0)) AS sum_quantity,sum(qtyreceived) AS qtyreceived  -- ptbom.zspm_projecttaskbom_id,
        FROM zspm_projecttaskbom ptbom
        WHERE 1=1
         AND ptbom.isactive = 'Y'
         AND ptbom.c_projecttask_id = v_projecttask_id
        GROUP BY ptbom.c_projecttask_id, ptbom.m_product_id, ptbom.receiving_locator
      ) LOOP

       -- wenn Materialbewegungen kleiner als Plan-Menge : verfuegbaren Lagerbestand ermitteln
       -- IF (cur_projecttaskbom.qtyreceived < cur_projecttaskbom.sum_quantity) THEN
          v_req_stock_qty := (cur_projecttaskbom.sum_quantity - cur_projecttaskbom.qtyreceived);
          v_sd_qtyonhand := m_bom_qty_onhand(cur_projecttaskbom.m_product_id, null, cur_projecttaskbom.receiving_locator);
                          --  (SELECT sd.qtyonhand FROM m_storage_detail sd
                          --   WHERE sd.m_product_id = cur_projecttaskbom.m_product_id
                          --     AND sd.m_locator_id = cur_projecttaskbom.receiving_locator);



          if v_req_stock_qty > v_sd_qtyonhand  then
             return false;
          end if;
       -- ELSE
       --   result := TRUE;
       -- END IF;

      END LOOP;
    ELSE
      v_message := '@zssm_projecttaskbomNotFound@'; --??
      RAISE EXCEPTION 'ERROR: % %', v_message, p_projecttask_id;
    END IF;
   -- finish
    RETURN true;
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'zssm_is_material_complete: ' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
  RETURN FALSE;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssm_is_dependendtasks_complete (
  p_projecttask_id   VARCHAR
 )
RETURNS BOOLEAN
AS $body$
/*
  Pruefung, ob alle direkten Vorgaenger zum Arbeitsgang abgeschlossen sind.
  Sind alle Vorgaenger abgeschlossen, ist die Pruefung erfolgreich.
  ERgänzung: Eigenschaft dependentstatuscheck prüfen (Prüfung wird dadurch Optional
*/

-- SELECT zssm_is_dependendtasks_complete('4ACDE1706DF34C79B0A404AB29A9CC17');
DECLARE
  v_message         VARCHAR;
  v_sum_incomplete  INTEGER;
BEGIN
  v_sum_incomplete :=
     (SELECT
        SUM(CASE WHEN (pt.iscomplete = 'Y') THEN (0) ELSE (1) END)
      FROM c_projecttask pt
      WHERE pt.c_projecttask_id
       IN (
         SELECT ptdep.dependsontask
         FROM zspm_projecttaskdep ptdep
         WHERE ptdep.c_projecttask_id = p_projecttask_id
         AND ptdep.dependentstatuscheck='Y'
          ));
   if coalesce(v_sum_incomplete,0)=0 then
      return true;
   else
      return false;
   end if;
   --RAISE NOTICE 'p_projecttask_id=%, v_sum_incomplete=%', p_projecttask_id, v_sum_incomplete;
   --RETURN (v_sum_incomplete = 0);
   return true;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'zssm_is_dependendtasks_complete:' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
  RETURN FALSE;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_DropView ('zssm_productionplan_taskdep_v');
CREATE OR REPLACE VIEW zssm_productionplan_taskdep_v AS
SELECT
	prptskdep.zssm_productionplan_taskdep_id AS zssm_productionplan_taskdep_v_id,
	prptskdep.zssm_productionplan_taskdep_id AS zssm_productionplan_taskdep_id,
	prptskdep.ad_client_id AS ad_client_id,
	prptskdep.ad_org_id AS ad_org_id,
	prptskdep.isactive AS isactive,
	prptskdep.created AS created,
	prptskdep.createdby AS createdby,
	prptskdep.updated AS updated,
	prptskdep.updatedby AS updatedby,
	prptskdep.c_project_id AS zssm_productionplan_v_id,
	prptskdep.sortno AS sortno,
	prptskdep.dependsontask AS dependsontask,
	prptskdep.zssm_productionplan_task_id AS zssm_productionplan_task_id,
	prptskdep.description AS description,
	prptskdep.stockrotation AS stockrotation,
  prptskdep.dependentstatuscheck
FROM zssm_productionplan_taskdep prptskdep;

CREATE OR REPLACE RULE zssm_productionplan_taskdep_v_insert AS
ON INSERT TO zssm_productionplan_taskdep_v DO INSTEAD
INSERT INTO zssm_productionplan_taskdep (
	zssm_productionplan_taskdep_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	c_project_id,
	sortno,
	dependsontask,
	zssm_productionplan_task_id,
	description,
	stockrotation,
  dependentstatuscheck  
) VALUES (
	NEW.zssm_productionplan_taskdep_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
  COALESCE(NEW.isactive,'Y'),
	COALESCE(NEW.created, now()),	
  NEW.createdby,
  COALESCE(NEW.updated, now()),
	NEW.updatedby,
	NEW.zssm_productionplan_v_id,
	NEW.sortno,
	NEW.dependsontask,
	NEW.zssm_productionplan_task_id,
	NEW.description,
	COALESCE(NEW.stockrotation, 'N'),
  COALESCE(NEW.dependentstatuscheck, 'N')
  );

CREATE OR REPLACE RULE zssm_productionplan_taskdep_v_update AS
ON UPDATE TO zssm_productionplan_taskdep_v DO INSTEAD
UPDATE zssm_productionplan_taskdep SET
	zssm_productionplan_taskdep_id = NEW.zssm_productionplan_taskdep_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	c_project_id = NEW.zssm_productionplan_v_id,
	sortno = NEW.sortno,
	dependsontask = NEW.dependsontask,
	zssm_productionplan_task_id = NEW.zssm_productionplan_task_id,
	description = NEW.description,
	stockrotation = NEW.stockrotation,
  dependentstatuscheck = NEW.dependentstatuscheck
WHERE
	zssm_productionplan_taskdep.zssm_productionplan_taskdep_id = NEW.zssm_productionplan_taskdep_id;
  
CREATE OR REPLACE RULE zssm_productionplan_taskdep_v_delete AS
ON DELETE TO zssm_productionplan_taskdep_v DO INSTEAD
DELETE FROM zssm_productionplan_taskdep WHERE
	zssm_productionplan_taskdep.zssm_productionplan_taskdep_id = old.zssm_productionplan_taskdep_id;


SELECT zsse_dropview('zssm_productionplan_task_v');
CREATE OR REPLACE VIEW zssm_productionplan_task_v AS
SELECT
	ppt.zssm_productionplan_task_id AS zssm_productionplan_task_v_id,
	ppt.zssm_productionplan_task_id AS zssm_productionplan_task_id,
	ppt.ad_client_id AS ad_client_id,
	ppt.ad_org_id AS ad_org_id,
	ppt.isactive AS isactive,
	ppt.created AS created,
	ppt.createdby AS createdby,
	ppt.updated AS updated,
	ppt.updatedby AS updatedby,
	ppt.sortno AS sortno,
	ppt.c_project_id AS zssm_productionplan_v_id,
	ppt.c_projecttask_id AS c_projecttask_id,
	ppt.c_projecttask_id AS zssm_workstep_prp_v_id,
	pt.value AS value,
	pt.name AS name,
	pt.description AS description,
	pt.assembly AS assembly,
	pt.m_product_id AS m_product_id,
        pt.forcematerialscan,
        pt.startonlywithcompletematerial,
	pt.percentrejects AS percentrejects,
	pt.issuing_locator AS issuing_locator,
	pt.receiving_locator AS receiving_locator,
	pt.timeperpiece,
	pt.setuptime,
	pt.c_color_id
FROM zssm_productionplan_task ppt, c_projecttask pt
where ppt.c_projecttask_id = pt.c_projecttask_id;
 
CREATE OR REPLACE RULE zssm_productionplan_task_v_insert AS
ON INSERT TO zssm_productionplan_task_v DO INSTEAD
INSERT INTO zssm_productionplan_task (
	zssm_productionplan_task_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	sortno,
	c_project_id,
	c_projecttask_id
) VALUES (
	NEW.zssm_productionplan_task_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
	COALESCE(NEW.isactive, 'Y'),
	COALESCE(NEW.created, now()),
	NEW.createdby,
	COALESCE(NEW.updated, now()),
	NEW.updatedby,
	NEW.sortno,
	NEW.zssm_productionplan_v_id,
	NEW.c_projecttask_id
  );

CREATE OR REPLACE RULE zssm_productionplan_task_v_update AS
ON UPDATE TO zssm_productionplan_task_v DO INSTEAD
UPDATE zssm_productionplan_task SET
	zssm_productionplan_task_id = NEW.zssm_productionplan_task_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	sortno = NEW.sortno,
	c_project_id = NEW.zssm_productionplan_v_id,
	c_projecttask_id = NEW.c_projecttask_id
WHERE
	zssm_productionplan_task.zssm_productionplan_task_id = NEW.zssm_productionplan_task_id;

CREATE OR REPLACE RULE zssm_productionplan_task_v_delete AS
ON DELETE TO zssm_productionplan_task_v DO INSTEAD
DELETE FROM zssm_productionplan_task WHERE
	zssm_productionplan_task.zssm_productionplan_task_id = old.zssm_productionplan_task_id;

  
CREATE OR REPLACE FUNCTION zspm_projecttask_post_trg()
RETURNS trigger AS
$body$
 -- AFTER INSERT ON zspm_projecttask
DECLARE
 cur_product_bom RECORD;
 v_description VARCHAR;
BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;  END IF;

  IF (TG_OP <> 'DELETE') then
    IF (TG_OP = 'INSERT') THEN
        if (select projectcategory from c_project where c_project_id=new.c_project_id) in ('CS','S','I','M','P') then
            -- Copy Indirect Costs
            FOR cur_product_bom IN (SELECT * FROM ma_indirect_cost WHERE ad_org_id in (new.ad_org_id,'0') and addauto2project='Y' and isactive='Y') 
            LOOP
                insert into zspm_ptaskindcostplan(zspm_ptaskindcostplan_id,c_projecttask_id, ad_client_id, ad_org_id, createdby, updatedby,ma_indirect_cost_id)
                values (get_uuid(), NEW.c_projecttask_id, NEW.ad_client_id, NEW.ad_org_id, NEW.createdby, NEW.updatedby, cur_product_bom.ma_indirect_cost_id);
            END LOOP;
        end if;
    -- copy m_product_bom to c_projecttask_bom
    -- c_projecttask_id must exist before inserting into zspm_projecttaskbom
    /*
      IF (NEW.isactive = 'Y')  THEN                 -- c_projecttask
        IF (isempty(NEW.c_project_id)) THEN         -- ist Baukasten
          IF (NOT isempty(NEW.m_product_id)) THEN   -- Artikel als Ergebnis des Arbeitsgangs
            FOR cur_product_bom IN (
              SELECT * FROM m_product_bom prdbom WHERE prdbom.m_product_id = NEW.m_product_id AND prdbom.isactive = 'Y'
            ) LOOP
          --  v_description := ' Baukasten ' || 'prdbom.m_product_id=' || cur_product_bom.m_product_id;
              RAISE NOTICE ' copy product_bom to c_projecttaskbom: m_product_bom_id=%, m_productbom_id=%', cur_product_bom.m_product_bom_id, cur_product_bom.m_productbom_id;
              INSERT INTO zspm_projecttaskbom (zspm_projecttaskbom_id, c_projecttask_id, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, quantity,line)
              VALUES (get_uuid(), NEW.c_projecttask_id, NEW.ad_client_id, NEW.ad_org_id, NEW.createdby, NEW.updatedby, cur_product_bom.m_productbom_id, cur_product_bom.bomqty,cur_product_bom.line);
            END LOOP;
          END IF;
        END IF;
      END IF;
      update zspm_projecttaskbom set issuing_locator=new.issuing_locator,receiving_locator=new.receiving_locator where c_projecttask_id=NEW.c_projecttask_id ;
    END IF; -- TG_OP = 'INSERT'
    IF (TG_OP = 'UPDATE') THEN
    -- copy m_product_bom to c_projecttask_bom
    -- c_projecttask_id must exist before inserting into zspm_projecttaskbom
      IF (NEW.isactive = 'Y')  THEN                 -- c_projecttask
        IF (isempty(NEW.c_project_id)) THEN         -- ist Baukasten
          IF (coalesce(NEW.m_product_id,'')!=coalesce(old.m_product_id,'')) THEN   -- Artikel als Ergebnis des Arbeitsgangs
            if (select count(*) from zspm_projecttaskbom where c_projecttask_id=new.c_projecttask_id)=0 then 
                FOR cur_product_bom IN (
                SELECT * FROM m_product_bom prdbom WHERE prdbom.m_product_id = NEW.m_product_id AND prdbom.isactive = 'Y'
                ) LOOP
            --  v_description := ' Baukasten ' || 'prdbom.m_product_id=' || cur_product_bom.m_product_id;
                RAISE NOTICE ' copy product_bom to c_projecttaskbom: m_product_bom_id=%, m_productbom_id=%', cur_product_bom.m_product_bom_id, cur_product_bom.m_productbom_id;
                INSERT INTO zspm_projecttaskbom (zspm_projecttaskbom_id, c_projecttask_id, ad_client_id, ad_org_id, createdby, updatedby, m_product_id, quantity,line)
                VALUES (get_uuid(), NEW.c_projecttask_id, NEW.ad_client_id, NEW.ad_org_id, NEW.createdby, NEW.updatedby, cur_product_bom.m_productbom_id, cur_product_bom.bomqty,cur_product_bom.line);
                END LOOP;
            end if;
          END IF;
        END IF;
        if ((coalesce(NEW.issuing_locator,'')!=coalesce(old.issuing_locator,'')) or (coalesce(NEW.receiving_locator,'')!=coalesce(old.receiving_locator,''))) 
           and (c_getconfigoption('productionlocatorfromproductdata',new.ad_org_id)='N') then 
              update zspm_projecttaskbom set issuing_locator=new.issuing_locator,receiving_locator=new.receiving_locator where c_projecttask_id=NEW.c_projecttask_id ;
        end if;
        
      END IF;
      */
    END IF; -- TG_OP = 'INSERT'
    if TG_OP = 'UPDATE' then
        if coalesce(NEW.startdate,trunc(now()))!=coalesce(OLD.startdate,trunc(now())) and NEW.startdate is not null then
            update zspm_projecttaskbom set date_plan=NEW.startdate where c_projecttask_id=NEW.c_projecttask_id;
        end if;
    END IF;
    RETURN NEW;
  ELSE
   -- (TG_OP 'DELETE')
    RETURN OLD;
  END IF;

END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zspm_projecttask_post_trg', 'c_projecttask');
CREATE TRIGGER zspm_projecttask_post_trg
  AFTER INSERT OR UPDATE
  ON c_projecttask FOR EACH ROW
  EXECUTE PROCEDURE zspm_projecttask_post_trg();


CREATE OR REPLACE FUNCTION zssm_Copy_ProductionPlan2Order (
  p_pinstance_id  VARCHAR  -- source to copy from
 )
RETURNS VARCHAR -- '@Success@'
AS $body$
-- SELECT zssm_Copy_ProductionPlan2Order('9A7D2288B8794CCCBE1B83DF81F44C73');  --> Plan > Order
-- SELECT zssm_Copy_ProductionPlan2Order('AA7D2288B8794CCCBE1B83DF81F44C73');  --> @zssm_ProductionPlanNotFound@

-- SELECT zssm_Copy_ProductionPlan2Order('ZSSM_PRODUCTIONPLAN_V_C_PROJECT2');  --> Plan > Order 'komplexes Netz'
DECLARE
  cur_Parameter           RECORD;
  v_message               VARCHAR   := '';
  v_now                   TIMESTAMP := now();
  v_ProductionPlan_id     VARCHAR;   -- Source
  v_ProductionOrder_id    VARCHAR;   -- Target, for link
  v_ProductionOrderValue  VARCHAR;   -- GUI inmput
  v_ProductionOrderName   VARCHAR;   -- GUI inmput
  v_sequence varchar;
  v_org varchar;
  v_ProductionStartDate   TIMESTAMP; -- GUI inmput
  v_ProductionQty         NUMERIC;   -- GUI inmput
  v_user_id               VARCHAR;
  v_link                  VARCHAR;
  v_product_id VARCHAR;
  v_value_name            VARCHAR;
BEGIN
  BEGIN
    IF(p_pinstance_ID IS NOT NULL) THEN
      PERFORM ad_update_pinstance(p_PInstance_ID, NULL, 'Y', NULL, NULL) ; -- 'Y'=processing

      SELECT pi.Record_ID, pi.ad_User_ID
      INTO v_ProductionPlan_id, v_user_id
      FROM ad_pinstance pi WHERE pi.ad_pinstance_ID = p_pinstance_ID;

      v_ProductionOrder_id := get_uuid();

      IF (v_ProductionPlan_id IS NULL) THEN
        RAISE NOTICE '%','Entry for PInstance not found - Using parameter &1 (ProductionPlan_id)=''' || p_pinstance_ID || ''' instead';
        v_ProductionPlan_id := p_pinstance_ID;  -- source
        v_ProductionQty := 2;
        v_user_id := CURRENT_USER;  -- tad
        v_ProductionOrderValue := 'PRO' || ' ' || (SELECT TO_CHAR(now(), 'DDD HH24:MI:SS'));
        v_ProductionOrderName := v_ProductionOrderValue;
        v_org:='0';
      ELSE
        v_message := 'ReadingParameters';
        FOR Cur_Parameter IN
          (SELECT para.*
           FROM ad_pinstance pi, ad_pinstance_Para para
           WHERE 1=1
            AND pi.ad_pinstance_ID = para.ad_pinstance_ID
            AND pi.ad_pinstance_ID = p_pinstance_ID
           ORDER BY para.SeqNo
          )
        LOOP
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('zssm_productionplan_v_id') ) THEN
            v_ProductionPlan_id := Cur_Parameter.p_string;
          END IF;
          
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('m_product_id') ) THEN
            v_product_id := Cur_Parameter.p_string;
          END IF;

          IF ( UPPER(Cur_Parameter.parametername) = UPPER('p_ProductionStartDate') ) THEN
            v_ProductionStartDate := Cur_Parameter.p_date;
          END IF;
          IF ( UPPER(Cur_Parameter.parametername) = UPPER('p_ProductionQty') ) THEN
            v_ProductionQty := Cur_Parameter.p_number;
          END IF;
          v_org:=Cur_Parameter.ad_org_id;
        END LOOP; -- Get Parameter
      END IF;
    END IF;
    -- Create Name and Value Automatically 
    v_sequence:= Ad_Sequence_Doc('DocumentNo_C_Project', v_org,'Y');
    select value,name into v_ProductionOrderValue,v_ProductionOrderName from  c_project where c_project_id=v_ProductionPlan_id;
    v_ProductionOrderValue:=substr(v_ProductionOrderValue,1,40-length(v_sequence))||v_sequence;
 -- plausi
    IF ( isempty(p_pinstance_ID) ) THEN
      RAISE EXCEPTION '% % % %', 'SQL-PROC zssm_Copy_ProduktionPlan2ProductionOrder: ', '@InvalidArguments@', 'p_pinstance_ID', COALESCE(p_pinstance_ID, '') ; -- GOTO EXCEPTION
    END IF;
    IF ( isempty(v_ProductionPlan_id) ) THEN
      RAISE EXCEPTION '% % %=''%''', '@InvalidArguments@', '@zssm_ProductionPlanNotFound@', 'v_ProductionPlan_id', COALESCE(v_ProductionPlan_id, ''); -- GOTO EXCEPTION
    END IF;
    IF ( isempty(v_ProductionOrder_ID) ) THEN
      RAISE EXCEPTION '% % %=''%''', '@InvalidArguments@', '@zssm_ProductionOrderNotFound@', 'zssm_ProductionOrder_ID', COALESCE(v_ProductionOrder_ID, ''); -- GOTO EXCEPTION
    END IF;

    v_message := '@process_started@';
    PERFORM ad_update_pinstance(p_pinstance_ID, v_user_id, 'Y', 0, v_Message) ; -- 'Y'=isProcessing, 0=success

  -- copy plan to order
    v_message := (SELECT zssm_Copy_ProductionPlan2Project (v_ProductionPlan_id, v_ProductionOrder_id, v_ProductionOrderValue, v_ProductionOrderName, v_ProductionStartDate, v_ProductionQty, v_user_id, v_product_id)); -- '@zssm_Plan2Order_copied@'

 -- finally update for inserted zssm_workstep_v / fire update-rule
 -- for future use
 -- UPDATE zssm_productionorder_v v SET btn_CopyWorkstep = 'Y' WHERE v.zssm_productionorder_v_id = v_ProductionOrder_id; -- set button AS used, just for documentation

 -- ToDo
    v_value_name := COALESCE(v_ProductionOrderValue, '') || ' - ' || v_ProductionOrderName; -- || ' - '|| v_ProductionOrder_id;
    v_link := (SELECT zsse_getmainfrompopup( v_ProductionOrder_id, 'inpzssmProductionorderVId', '/org.openbravo.zsoft.serprod.ProductionOrder/ProductionOrderCF6D6BC0255A47DFBD4FF6F8BEBA0C71_Relation.html',  v_ProductionOrderName));
 --   v_link := (SELECT zsse_htmlLinkDirectKey('../org.openbravo.zsoft.serprod.ProductionOrder/ProductionOrderCF6D6BC0255A47DFBD4FF6F8BEBA0C71_Relation.html', v_ProductionOrder_id, v_value_name));
 -- v_link := (SELECT zsse_htmldirectlink('../org.openbravo.zsoft.serprod.ProductionOrder/ProductionOrderCF6D6BC0255A47DFBD4FF6F8BEBA0C71_Relation.html', 'document.frmMain.inpzssmProductionorderVId', v_ProductionOrder_id, v_value_name ));
 -- v_message := v_message  || '</br>' || v_link || '<Input type="hidden" name="inpzssmProductionorderVId" id="Zssm_Productionorder_V_ID" value="' || v_ProductionOrder_id || '"></INPUT>';
    v_message := v_message  || '</br>' || v_link;
    PERFORM ad_update_pinstance(p_pinstance_ID, NULL, 'N', 1, v_Message) ; -- NULL=p_ad_user_id, 'N'=isProcessing, 1=success

    RETURN v_message;
  END; --BODY
EXCEPTION
WHEN OTHERS THEN
  v_message := '@Error@=' || 'SQL-PROC zssm_Copy_ProduktionPlan2ProductionOrder: ' || SQLERRM;
  RAISE NOTICE '%', v_message;
  PERFORM AD_UPDATE_pinstance(p_pinstance_ID, NULL, 'N', 0, v_message);
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql';



CREATE OR REPLACE FUNCTION zssm_builddependentworksteptree(p_project varchar,p_followtasks varchar,OUT ptask varchar,out dependson varchar) RETURNS SETOF RECORD
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Builds the Tree of dependent Worksteps in correct order


*****************************************************/
v_cur record;
v_cur2 record;
followerslist varchar:='';
TYPE_Ref REFCURSOR;
v_cursor TYPE_Ref%TYPE;
v_sql varchar;
BEGIN
   -- ENTRY
   if p_followtasks is null then
      FOR v_cur IN
       (SELECT pt.c_projecttask_id FROM c_projecttask pt 
            WHERE pt.c_project_id = p_project and not exists (select 0 from zspm_projecttaskdep dep where pt.c_projecttask_id=dep.c_projecttask_id) 
        ORDER BY seqno
       )
      LOOP
        ptask:=v_cur.c_projecttask_id;
        dependson:=null;
        RETURN NEXT;
        for v_cur2 in (select * from zspm_projecttaskdep where zspm_projecttaskdep.dependsontask = v_cur.c_projecttask_id)
        LOOP
            if followerslist!='' then 
                followerslist:=followerslist||',';
            end if;
            followerslist:=followerslist||chr(39)||v_cur2.c_projecttask_id||chr(39);
        END LOOP;
      END LOOP;
   else
   -- TREE
      raise notice '%','FL:'||p_followtasks;      
      v_sql:='SELECT pt.c_projecttask_id FROM c_projecttask pt  WHERE pt.c_projecttask_id in ('||p_followtasks||') order by seqno';
      OPEN v_cursor FOR EXECUTE v_sql;
      LOOP
        FETCH v_cursor INTO v_cur;
        EXIT WHEN NOT FOUND;
        for v_cur2 in (select dependsontask from  zspm_projecttaskdep where c_projecttask_id=v_cur.c_projecttask_id)
        LOOP
            ptask:=v_cur.c_projecttask_id;
            dependson:=v_cur2.dependsontask;
            raise notice '%','DP:'||ptask;
            RETURN NEXT;
        END LOOP;
        for v_cur2 in (select * from zspm_projecttaskdep where zspm_projecttaskdep.dependsontask = v_cur.c_projecttask_id)
        LOOP
            if followerslist!='' then 
                followerslist:=followerslist||',';
            end if;
            followerslist:=followerslist||chr(39)||v_cur2.c_projecttask_id||chr(39);
        END LOOP;
      END LOOP;
   end if;
   -- TREE Recursion
   if followerslist!='' then
      -- Call me recursive
      for v_cur in (select * from  zssm_builddependentworksteptree(p_project,followerslist))
      LOOP
         ptask:=v_cur.ptask;
         dependson:=v_cur.dependson;
        RETURN NEXT;
      END LOOP;
   END IF;
END;
$_$  LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zssm_Copy_ProductionPlan2Project (
  p_ProductionPlan_ID    VARCHAR, -- source to copy from
  p_ProductionOrder_ID   VARCHAR, -- target to copy to
  p_ProductionOrderValue VARCHAR, -- NEW productionOrderValue
  p_ProductionOrderName  VARCHAR, -- NEW productionOrderName
  p_startDate            TIMESTAMP,
  p_qty                  NUMERIC,
  p_user_id VARCHAR,
  p_product_id VARCHAR
 )
RETURNS VARCHAR -- '@Success@'
AS $body$
DECLARE
  v_message  VARCHAR;
  v_name varchar;
  v_now      TIMESTAMP := now();
  v_user_id  VARCHAR := p_user_id;
  v_zssm_productionOrder_v  c_project%ROWTYPE;
  cur_projecttask RECORD;
  v_PRO_Value VARCHAR :=  'PRO' || ' ' || (SELECT TO_CHAR(now(), 'DDD HH24:MI:SS'));
  v_taskstarttime timestamp;
  v_taskendtime timestamp;
  v_taskenddate timestamp;
  v_workminutes numeric;
  v_workbeginminutes  numeric;
  v_needminutes  numeric;
  v_consumedminutesoffset numeric;
  v_org varchar;
  v_provalue varchar;
BEGIN
  BEGIN
    v_message := 'copying plan to order';
 --RAISE NOTICE '% %', 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX SQL-PROC : zssm_Copy_ProductionPlan2Project', v_message;
    IF (isempty(p_user_id)) THEN
      v_user_id := CURRENT_USER;
    END IF;
    SELECT * FROM c_project ppv -- zssm_productionplan_v
    INTO v_zssm_productionOrder_v -- ROWTYPE
    WHERE ppv.c_project_id = p_ProductionPlan_ID AND ppv.projectcategory = 'PRP'; -- PRoductionPlan
    IF (NOT isEmpty(v_zssm_productionOrder_v.c_project_id) ) THEN
      v_zssm_productionOrder_v.c_project_id := p_ProductionOrder_ID; -- set target
      v_zssm_productionOrder_v.created := v_now;
      v_zssm_productionOrder_v.createdby := v_user_id;
      v_zssm_productionOrder_v.isactive := 'Y';
      v_zssm_productionOrder_v.updated := v_now;
      v_zssm_productionOrder_v.updatedby := v_user_id;
      v_zssm_productionOrder_v.value := COALESCE(p_ProductionOrderValue, v_PRO_Value);
      v_zssm_productionOrder_v.name := COALESCE(p_ProductionOrderName, v_zssm_productionOrder_v.name);
      v_zssm_productionOrder_v.description := v_zssm_productionOrder_v.description;
      v_zssm_productionOrder_v.startDate := NULL;--p_startDate; -- even null
      v_zssm_productionOrder_v.datefinish := NULL;
      v_zssm_productionOrder_v.m_pricelist_id := NULL;
      v_zssm_productionOrder_v.projectcategory := 'PRO';
      v_zssm_productionOrder_v.projectstatus := 'OP'; -- Draft
      v_zssm_productionOrder_v.prpreference := p_ProductionPlan_ID; -- caused by
      v_org:=v_zssm_productionOrder_v.ad_org_id;
    --RAISE NOTICE ' INSERT INTO c_project: v_zssm_productionOrder_v.c_project_id=%, v_zssm_productionOrder_v.value=%, v_zssm_productionOrder_v.name=%', v_zssm_productionOrder_v.c_project_id, v_zssm_productionOrder_v.value, v_zssm_productionOrder_v.name;
      INSERT INTO c_project SELECT v_zssm_productionOrder_v.*; -- ROWTYPE  
      -- RAISE NOTICE '%', 'LOOP update each projecttaskbom_id - fire update-trigger zspm_projecttask_trg() to set zspm_projecttaskbom.quantity from qty';
      
      
      -- Der Trigger generiert Worksteps und BOM:
      -- fire zspm_project_copyplan2order_trg() AFTER INSERT ON c_project: INSERT c_projecttask, INSERT zspm_projecttaskbom, INSERT zspm_ptaskhrplan, ..
      -- Hier werden nur die Mengen angepasst -> Relevant bei mehreren Tasks in 1 Production-Order
      perform zssm_generateproductionboms(p_productionorder_id, p_product_id, coalesce(p_qty,1));
      FOR cur_projecttask IN -- i.d.R immer 1x Recursion -> Nur  bei mehreren Tasks in 1 Production-Order werden meherer Recursionen nötig.
       (SELECT * FROM zssm_builddependentworksteptree(p_ProductionOrder_ID,null)
       )
      LOOP
            if cur_projecttask.dependson is null then -- Im Plan Verkete Tasks? (dependson)
                if EXTRACT(HOUR FROM p_startDate)+EXTRACT(MINUTE FROM p_startDate)!=0 then
                    v_taskstarttime:=p_startDate;
                    v_consumedminutesoffset:=EXTRACT(HOUR FROM v_taskstarttime)*60+EXTRACT(MINUTE FROM v_taskstarttime);
                else
                    select EXTRACT(HOUR FROM  coalesce(c_getorgworkbegintime(v_org,workdate),workbegintime))*60+EXTRACT(MINUTE FROM  coalesce(c_getorgworkbegintime(v_org,workdate),workbegintime)) into v_workbeginminutes from c_workcalender where trunc(workdate)=trunc(p_startDate);
                    v_taskstarttime:=p_startDate + v_workbeginminutes * interval '1 minutes';
                    v_consumedminutesoffset:=0;
                end if;
            else
                select max(enddate) into v_taskstarttime from c_projecttask where c_projecttask_id=cur_projecttask.dependson;
            end if;
            -- Calculate the Time need to execute workstep
            select EXTRACT(HOUR FROM  coalesce(c_getorgworkbegintime(v_org,workdate),workbegintime))*60+EXTRACT(MINUTE FROM  coalesce(c_getorgworkbegintime(v_org,workdate),workbegintime)),
                    coalesce(c_getorgworktime(v_org,workdate),worktime)*60 into v_workbeginminutes,v_workminutes from c_workcalender where trunc(workdate)=trunc(v_taskstarttime);
            select timeplanned,name into v_needminutes,v_name from c_projecttask pt WHERE pt.c_projecttask_id = cur_projecttask.ptask;
            v_taskendtime:=v_taskstarttime + v_needminutes * interval '1 minutes';
            v_taskenddate:=trunc(v_taskstarttime);
            --perform logg(v_name||'-MIN:'||v_needminutes||'TET:'||v_taskendtime||'TED'||v_taskenddate||' WM:'||v_workbeginminutes+v_workminutes||'EXT:'||EXTRACT(HOUR FROM v_taskendtime)*60+EXTRACT(MINUTE FROM v_taskendtime));
            -- End is not the same date or end exeeds workhours
            WHILE trunc(v_taskendtime)!=trunc(v_taskenddate) or v_workbeginminutes+v_workminutes < EXTRACT(HOUR FROM v_taskendtime)*60+EXTRACT(MINUTE FROM v_taskendtime)
            LOOP
                v_taskenddate:=v_taskenddate+1;
                v_needminutes:=v_needminutes-v_workminutes+v_consumedminutesoffset;
                if v_needminutes<0 then
                   v_needminutes:=0;
                end if;
                v_taskendtime:=v_taskenddate + (v_workbeginminutes + v_needminutes) * INTERVAL '1 minutes';
                v_consumedminutesoffset:=0; 
                select EXTRACT(HOUR FROM coalesce(c_getorgworkbegintime(v_org,workdate),workbegintime))*60+EXTRACT(MINUTE FROM coalesce(c_getorgworkbegintime(v_org,workdate),workbegintime)),
                       coalesce(c_getorgworktime(v_org,workdate),worktime)*60 into v_workbeginminutes,v_workminutes from c_workcalender where trunc(workdate)=trunc(v_taskenddate);
                --perform logg(v_name||'-IN!MIN:'||v_needminutes||'TET:'||v_taskendtime||'TED'||v_taskenddate||' WM:'||v_workbeginminutes+v_workminutes||'EXT:'||EXTRACT(HOUR FROM v_taskendtime)*60+EXTRACT(MINUTE FROM v_taskendtime));
                --raise notice '%' , 'IN!MIN:'||v_needminutes||'TET:'||v_taskendtime||'TED'||v_taskenddate||' WM:'||v_workbeginminutes+v_workminutes||'EXT:'||EXTRACT(HOUR FROM v_taskendtime)*60+EXTRACT(MINUTE FROM v_taskendtime);
            END LOOP;

            UPDATE c_projecttask pt
            SET startdate =  v_taskstarttime ,
                enddate =  v_taskendtime
            WHERE pt.c_projecttask_id = cur_projecttask.ptask;
      END LOOP;
      -- The Production Order Name may be identical to the First essembly defined in teh Production Order
      select min(value) into v_provalue from c_projecttask where c_project_id=p_ProductionOrder_ID;
      update c_project set value=v_provalue, 
      startdate= (select min(startdate) from c_projecttask where c_project_id=p_ProductionOrder_ID),
      datefinish= (select max(enddate) from c_projecttask where c_project_id=p_ProductionOrder_ID),
      note=(select string_agg(coalesce(p.value||'-'||p.name,'')||' ,  '||to_char(coalesce(pt.qty,0)),',') from m_product p,c_projecttask pt where p.m_product_id=pt.m_product_id and pt.c_project_id= p_ProductionOrder_ID) where c_project_id=p_ProductionOrder_ID;
      v_message := '@zssm_Plan2Order_copied@' || ' - ' || v_zssm_productionOrder_v.value;
    ELSE
      v_message := '@zssm_ProductionPlanNotFound@ p_ProductionPlan_ID=''|| p_ProductionPlan_ID ||''';
      RAISE EXCEPTION '%', v_message;
    END IF;
   -- RAISE NOTICE '%', 'YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYEND COPY PLAN';
    RETURN '@Success@' || ' ' || v_message;
  END;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'zssm_Copy_ProductionPlan2Project:' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
  RETURN v_message;
END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zspm_project_copyplan2order_trg (
)
RETURNS trigger AS
$body$
DECLARE
  cur_prp_taskdep RECORD;                 -- zssm_productionplan_taskdep
  cur_prp_task RECORD;                    -- zssm_productionplan_task
  cur_zspm_projecttaskbom RECORD;
  cur_zspm_ptaskhrplan RECORD;
  cur_zspm_ptaskmachineplan RECORD;
  v_message VARCHAR;
  v_projecttask c_projecttask%ROWTYPE;
  v_projecttask_id VARCHAR;
  v_stockRotation CHAR(1);
  v_zspm_projecttaskbom zspm_projecttaskbom%ROWTYPE;
  v_zspm_ptaskhrplan zspm_ptaskhrplan%ROWTYPE;
  v_zspm_ptaskmachineplan zspm_ptaskmachineplan%ROWTYPE;
  v_zssm_productionplan_task zssm_productionplan_task%ROWTYPE;
  v_zssm_productionplan_taskdep zssm_productionplan_taskdep%ROWTYPE;
BEGIN
 -- AFTER INSERT ON c_project
  IF AD_isTriggerEnabled()='N' THEN IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;
--RAISE NOTICE '%: %', ' -> FUNCTION c_project_copyPlan2Order_trg ()', NEW.prpreference;

  IF (TG_OP = 'INSERT') THEN
    FOR cur_prp_task IN
      (SELECT * FROM zssm_productionplan_task pptask
       WHERE pptask.c_project_id = NEW.prpreference
        AND pptask.isactive = 'Y'
       ORDER BY pptask.sortno)
    LOOP
      SELECT * FROM c_projecttask tsk INTO v_projecttask WHERE tsk.c_projecttask_id = cur_prp_task.c_projecttask_id; -- ROWTYPE
      v_projecttask.c_projecttask_id := get_uuid();     -- productionOrder
      v_projecttask.c_project_id := NEW.c_project_id;   -- productionOrder
      v_projecttask.zssm_productionplan_task_id := cur_prp_task.zssm_productionplan_task_id; -- Vorlage
      v_projecttask.created := NEW.created;             -- c_project.created
      v_projecttask.createdby := NEW.updatedby;
      v_projecttask.updated := NEW.updated;             -- c_project.updated
      v_projecttask.updatedby := NEW.updatedby;
      v_projecttask.value := (SELECT AD_Sequence_Doc('DocumentNo_zssm_workstep_v', v_projecttask.ad_client_id, 'Y'));
      v_projecttask.name := v_projecttask.name;
      v_projecttask.taskbegun := 'N';                   -- alter table c_projecttask alter column taskbegun set default 'N'; 2.6.64.120 2012-11-23
      v_projecttask.seqNo = cur_prp_task.SortNo;
      v_projecttask.qty := 1;                           -- set by trigger, if (m_product_id IS NOT NULL) ??
      -- v_projecttask.m_product_id
      -- v_projecttask.outsourcing
      v_projecttask.plannedcost := NULL;
      v_projecttask.c_orderline_id := NULL;
      -- v_projecttask.receiving_locator
      -- v_projecttask.issuing_locator
      -- v_projecttask.assembly
      -- v_projecttask.getmaterialfromstock
      -- v_projecttask.returnmaterialtostock
      INSERT INTO c_projecttask SELECT v_projecttask.*; -- ROWTYPE
     -- > BEFORE: zspm_projecttask_trg()
     -- > AFTER:  zspm_projecttask_post_trg() copy m_product_bom to c_projecttask_bom (Baukasten-Stckliste)
--    RAISE NOTICE ' v_projecttask.m_product_id=%, cur_prp_task.c_projecttask_id=%', v_projecttask.m_product_id, cur_prp_task.c_projecttask_id ;
     -- projecttaskbom zum Plan

      FOR cur_zspm_projecttaskbom IN
       -- alle id zu projekttask abarbeiten
       (SELECT zspm_projecttaskbom_id FROM zspm_projecttaskbom ptbom
        WHERE ptbom.c_projecttask_id = cur_prp_task.c_projecttask_id
         AND ptbom.isactive = 'Y')
      LOOP
        -- zur id den projekttask in rowtype-buffer uebertragen
        SELECT * FROM zspm_projecttaskbom zspmpttb INTO v_zspm_projecttaskbom   -- %ROWTYPE
        WHERE zspmpttb.zspm_projecttaskbom_id = cur_zspm_projecttaskbom.zspm_projecttaskbom_id;
        v_zspm_projecttaskbom.zspm_projecttaskbom_id := get_uuid();              -- neue id fuer projecttaskbom
        v_zspm_projecttaskbom.c_projecttask_id = v_projecttask.c_projecttask_id; -- neue id
        v_zspm_projecttaskbom.created := NEW.created;                            -- c_project.created
        v_zspm_projecttaskbom.createdby := NEW.updatedby;
        v_zspm_projecttaskbom.updated := NEW.updated;                            -- c_project.updated
        v_zspm_projecttaskbom.updatedby := NEW.updatedby;
        v_zspm_projecttaskbom.qtyReserved := 0;
        v_zspm_projecttaskbom.qtyReceived := 0;
        v_zspm_projecttaskbom.qtyInrequisition := 0;
        v_zspm_projecttaskbom.qty_plan := NULL;  -- Verschnitt
--        IF ((v_zspm_projecttaskbom.date_plan < now()) OR (v_zspm_projecttaskbom.date_plan IS NULL)) THEN
--          v_zspm_projecttaskbom.date_plan := now();
 --       END IF;

        INSERT INTO zspm_projecttaskbom SELECT v_zspm_projecttaskbom.*; -- %ROWTYPE
        -- > AFTER: zspm_projecttaskbom_trg(): AFTER INSERT OR UPDATE OR DELETE : projecttask:@zspm_NoChangeOutsourcing@
      END LOOP;

     -- zspm_ptaskhrplan zum Plan
      FOR cur_zspm_ptaskhrplan IN
       -- alle id zu projekttask abarbeiten
       (SELECT zspm_ptaskhrplan_id FROM zspm_ptaskhrplan hrplan
        WHERE hrplan.c_projecttask_id = cur_prp_task.c_projecttask_id       -- 'C_PROJECTTASK_ID_PLAN2_b_0000000'
         AND hrplan.isactive = 'Y')
      LOOP
        -- zur id den projekttask in rowtype-buffer uebertragen
        SELECT * FROM zspm_ptaskhrplan zspmhrplan INTO v_zspm_ptaskhrplan       -- %ROWTYPE
        WHERE zspmhrplan.zspm_ptaskhrplan_id = cur_zspm_ptaskhrplan.zspm_ptaskhrplan_id;
        v_zspm_ptaskhrplan.zspm_ptaskhrplan_id := get_uuid();                   -- neue id fuer projecttaskbom
        v_zspm_ptaskhrplan.c_projecttask_id = v_projecttask.c_projecttask_id;   -- neue id fuer order
        v_zspm_ptaskhrplan.created := NEW.created;                              -- c_project.created
        v_zspm_ptaskhrplan.createdby := NEW.updatedby;
        v_zspm_ptaskhrplan.updated := NEW.updated;                              -- c_project.updated
        v_zspm_ptaskhrplan.updatedby := NEW.updatedby;
       -- rowtype-buffer in DB ausgeben
        INSERT INTO zspm_ptaskhrplan SELECT v_zspm_ptaskhrplan.*;               -- %ROWTYPE
        -- excecute zspm_ptaskhrplan_trg ->  fire trigger on c_ProjectTask to calculate Plan-Costs
      END LOOP;

     -- zspm_ptaskmachineplan zum Plan
      FOR cur_zspm_ptaskmachineplan IN
       -- alle id zu projekttask abarbeiten
       (SELECT zspm_ptaskmachineplan_id FROM zspm_ptaskmachineplan hrplan
        WHERE hrplan.c_projecttask_id = cur_prp_task.c_projecttask_id       -- 'C_PROJECTTASK_ID_PLAN2_b_0000000'
         AND hrplan.isactive = 'Y')
      LOOP
        -- zur id den projekttask in rowtype-buffer uebertragen
        SELECT * FROM zspm_ptaskmachineplan zspmmchplan INTO v_zspm_ptaskmachineplan -- %ROWTYPE
        WHERE zspmmchplan.zspm_ptaskmachineplan_id = cur_zspm_ptaskmachineplan.zspm_ptaskmachineplan_id;
        v_zspm_ptaskmachineplan.zspm_ptaskmachineplan_id := get_uuid();         -- neue id fuer projecttaskbom
        v_zspm_ptaskmachineplan.c_projecttask_id = v_projecttask.c_projecttask_id;   -- neue id fuer order
        v_zspm_ptaskmachineplan.created := NEW.created;                         -- c_project.created
        v_zspm_ptaskmachineplan.createdby := NEW.updatedby;
        v_zspm_ptaskmachineplan.updated := NEW.updated;                         -- c_project.updated
        v_zspm_ptaskmachineplan.updatedby := NEW.updatedby;
       -- rowtype-buffer in DB ausgeben
        INSERT INTO zspm_ptaskmachineplan SELECT v_zspm_ptaskmachineplan.*;     -- %ROWTYPE
        -- excecute zspm_ptaskhrplan_trg ->  fire trigger on c_ProjectTask to calculate Plan-Costs
      END LOOP;

    END LOOP;

    INSERT INTO zspm_projecttaskdep (
      zspm_projecttaskdep_id, ad_client_id, ad_org_id, isactive, created, createdby, updated, updatedby,
      dependsontask, c_projecttask_id, stockRotation,sortno) -- Vorgaenger, Nachfolger, Lagerbewegung
    SELECT
      get_uuid(), NEW.ad_client_id, NEW.ad_org_id, 'Y', NEW.created, NEW.createdby, NEW.updated, NEW.updatedby,
     (SELECT ptv.c_projecttask_id FROM c_projecttask ptv
      WHERE ptv.zssm_productionplan_task_id = prptaskdep.dependsontask AND ptv.c_project_id = NEW.c_project_id),
     (SELECT ptn.c_projecttask_id FROM c_projecttask ptn
      WHERE ptn.zssm_productionplan_task_id = prptaskdep.zssm_productionplan_task_id AND ptn.c_project_id = NEW.c_project_id),
      prptaskdep.stockrotation,sortno
    FROM zssm_productionplan_taskdep prptaskdep
    WHERE 1=1
     AND prptaskdep.c_project_id = NEW.prpreference;

  END IF; -- TG_OP = 'INSERT'

  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    v_message := '@Error@' || ' ' || TG_NAME || ' ' || SQLERRM;
    RAISE EXCEPTION '%', v_message;
    END;
$body$
LANGUAGE 'plpgsql';


SELECT zsse_droptrigger('zspm_project_copyPlan2Order_trg', 'c_project');
CREATE TRIGGER zspm_project_copyPlan2Order_trg
  AFTER INSERT
  ON c_project FOR EACH ROW
  EXECUTE PROCEDURE zspm_project_copyPlan2Order_trg();


CREATE OR REPLACE FUNCTION zssm_productionplan_taskdep_stockroation_trg ()
RETURNS trigger AS
$body$
DECLARE
 cur_prp_taskdep RECORD;    -- zssm_productionplan_taskdep
 v_projecttask_id VARCHAR;
 v_workstep_name VARCHAR;
 v_description VARCHAR;
 v_tasklist VARCHAR[];      -- dyn. erweiterbares Array
BEGIN
 -- AFTER INSERT OR DELETE ON zssm_productionplan_taskdep
  IF AD_isTriggerEnabled()='N' THEN IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT') THEN
--  RAISE NOTICE 'AFTER INSERT stockrotation_trg() % von % und % einfuegen', NEW.c_project_id, NEW.dependsontask, NEW.zssm_productionplan_task_id;
    UPDATE zssm_productionplan_taskdep dep SET
      stockrotation = 'Y',
      updated = NEW.updated,
      updatedby = NEW.updatedby
    WHERE dep.zssm_productionplan_taskdep_id IN
     (SELECT pt.zssm_productionplan_taskdep_id FROM zssm_productionplan_taskdep pt
      WHERE 1=1
       AND pt.c_project_id = NEW.c_project_id
       AND pt.dependsontask = NEW.dependsontask
      ORDER BY pt.sortno);
  END IF; -- TG_OP = 'INSERT'

  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;

END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zssm_productionplan_taskdep_stockroation_trg', 'zssm_productionplan_taskdep');
CREATE TRIGGER zssm_productionplan_taskdep_stockroation_trg
  AFTER INSERT
  ON zssm_productionplan_taskdep FOR EACH ROW
  EXECUTE PROCEDURE zssm_productionplan_taskdep_stockroation_trg();

SELECT zsse_DropView ('zssm_productionorder_taskdep_v');
CREATE OR REPLACE VIEW zssm_productionorder_taskdep_v AS
SELECT
	zspm_projecttaskdep.zspm_projecttaskdep_id AS zssm_productionorder_taskdep_v_id,
	zspm_projecttaskdep.zspm_projecttaskdep_id AS zspm_projecttaskdep_id,
	zspm_projecttaskdep.ad_client_id AS ad_client_id,
	zspm_projecttaskdep.ad_org_id AS ad_org_id,
	zspm_projecttaskdep.isactive AS isactive,
	zspm_projecttaskdep.created AS created,
	zspm_projecttaskdep.createdby AS createdby,
	zspm_projecttaskdep.updated AS updated,
	zspm_projecttaskdep.updatedby AS updatedby,
	(select c_project_id from c_projecttask where c_projecttask.c_projecttask_id = zspm_projecttaskdep.c_projecttask_id) AS zssm_productionorder_v_id,
	zspm_projecttaskdep.sortno AS sortno,
	zspm_projecttaskdep.dependsontask AS dependsontask,
	zspm_projecttaskdep.c_projecttask_id AS c_projecttask_id,
	zspm_projecttaskdep.description AS description,
	zspm_projecttaskdep.stockrotation AS stockrotation,
	zspm_projecttaskdep.dependentstatuscheck
FROM zspm_projecttaskdep;

CREATE OR REPLACE RULE zssm_productionorder_taskdep_v_insert AS
ON INSERT TO zssm_productionorder_taskdep_v DO INSTEAD
INSERT INTO zspm_projecttaskdep (
	zspm_projecttaskdep_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	sortno,
	dependsontask,
	c_projecttask_id,
	description,
	stockrotation,
	dependentstatuscheck
) VALUES (
	NEW.zssm_productionorder_taskdep_v_id,
	NEW.ad_client_id,
	NEW.ad_org_id,
	NEW.isactive,
	NEW.created,
	NEW.createdby,
	NEW.updated,
	NEW.updatedby,
	NEW.sortno,
	NEW.dependsontask,
	NEW.c_projecttask_id,
	NEW.description,
	NEW.stockrotation,
	NEW.dependentstatuscheck);

CREATE OR REPLACE RULE zssm_productionorder_taskdep_v_update AS
ON UPDATE TO zssm_productionorder_taskdep_v DO INSTEAD
UPDATE zspm_projecttaskdep SET
	zspm_projecttaskdep_id = NEW.zssm_productionorder_taskdep_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	sortno = NEW.sortno,
	dependsontask = NEW.dependsontask,
	c_projecttask_id = NEW.c_projecttask_id,
	description = NEW.description,
	stockrotation = NEW.stockrotation,
	dependentstatuscheck=NEW.dependentstatuscheck
WHERE
	zspm_projecttaskdep.zspm_projecttaskdep_id = NEW.zssm_productionorder_taskdep_v_id;

CREATE OR REPLACE RULE zssm_productionorder_taskdep_v_delete AS
ON DELETE TO zssm_productionorder_taskdep_v DO INSTEAD
DELETE FROM zspm_projecttaskdep WHERE
	zspm_projecttaskdep.zspm_projecttaskdep_id = old.zssm_productionorder_taskdep_v_id;



CREATE OR REPLACE FUNCTION zspm_projecttaskdep_circle (
  p_projecttask_id VARCHAR,
  p_productionorder_task_id VARCHAR,
  p_tasklist VARCHAR[]
 )
RETURNS BOOLEAN
AS $body$
DECLARE
  cur_dependsontask RECORD;
  j INTEGER := 0;
  ret BOOLEAN := TRUE;
  v_cmd VARCHAR;
  v_contains BOOLEAN := FALSE;
  v_message  VARCHAR;
  v_tasklist VARCHAR[]:=p_tasklist;
BEGIN
--  RAISE NOTICE '%', '';
--  RAISE NOTICE 'zspm_projecttaskdep_circle(): ''%'', j=%', p_projecttask_id, j;

 -- Abbruchbedingung
  IF (isempty(v_tasklist[0])) THEN
 -- bei erstem Aufruf die beabsichtigte Beziehung in Liste ausgeben, noch nicht in DB wg. BEFORE INSERT
    v_tasklist[0] := p_projecttask_id;
 -- doppelter Schlüsselwert verletzt Unique-Constraint »zspm_projecttaskdep_key«
    IF ((SELECT COUNT(*) FROM zspm_projecttaskdep taskdep
         WHERE taskdep.dependsontask = p_projecttask_id AND taskdep.c_projecttask_id = p_productionorder_task_id) <> 0) THEN
      RAISE EXCEPTION '@zspm_relation_existent@';
    END IF;
  ELSE
    j := 0;
    LOOP
      IF (v_tasklist[j] IS NOT NULL) THEN
        IF (v_tasklist[j] = p_productionorder_task_id) THEN
          RAISE EXCEPTION '@zspm_relation_recursive@';
       -- RAISE NOTICE '     rekursive Zuordnungsbeziehung zu Vorgang % nicht erlaubt', p_projecttask_id;
 --       RETURN;
        END IF;
      ELSE
        EXIT;
      END IF;
      j := j + 1;
    END LOOP;
  END IF;

  j := 0;
  FOR cur_dependsontask IN
  (
    SELECT tskdep.dependsontask FROM zspm_projecttaskdep tskdep WHERE tskdep.c_projecttask_id = p_projecttask_id
  )
  LOOP
   -- zur Liste hinzufuegen, wenn nicht vorhanden
 -- RAISE NOTICE ' Vorgaenger=% zu % pruefen', cur_dependsontask.dependsontask, p_projecttask_id;
    v_contains := FALSE;
    LOOP
      IF (v_tasklist[j] IS NOT NULL) THEN
        IF (v_tasklist[j] = cur_dependsontask.dependsontask) THEN
          v_contains := (v_tasklist[j] = cur_dependsontask.dependsontask);
          EXIT;
        END IF;
      ELSE
        EXIT;
      END IF;
      j := j + 1;
    END LOOP;

   -- Vorgaenger in Liste zufuegen
    IF (NOT v_contains) THEN
     IF (v_tasklist[j] IS NULL) THEN
   -- RAISE NOTICE ' fuege Vorgaenger hinzu: v_tasklist[%]= ''%'' ', j, cur_dependsontask.dependsontask; -- v_tasklist[%]=''%'''
      v_tasklist[j] := cur_dependsontask.dependsontask;
      ret := (SELECT zspm_projecttaskdep_circle(cur_dependsontask.dependsontask, p_productionorder_task_id, v_tasklist)); -- suche Vorgaenger
     END IF;
    END IF;

  END LOOP;
  RETURN ret;
 END;
$body$
LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION zspm_projecttaskdep_taskdep_trg ()
RETURNS trigger AS
$body$
DECLARE
 v_projecttask_id VARCHAR;
 v_workstep_name VARCHAR;
 v_description VARCHAR;

 v_tasklist VARCHAR[];      -- dyn. erweiterbares Array
 v_message VARCHAR;
BEGIN -- BEFORE INSERT ON zspm_projecttaskdep
 BEGIN
  IF AD_isTriggerEnabled()='N' THEN IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
  END IF;

  IF (TG_OP = 'INSERT') THEN
    IF (NEW.sortno IS NULL) THEN
      NEW.sortno := (SELECT COALESCE(MAX(sortno),0)+10 AS DefaultValue FROM zspm_projecttaskdep ppwsl WHERE ppwsl.c_projecttask_id = NEW.c_projecttask_id);
    END IF;

 -- RAISE NOTICE 'BEFORE INSERT %: Versuche Vorgangsbeziehung von % zu % zuzuordnen', TG_NAME, NEW.dependsontask, NEW.c_projecttask_id;
    IF (isempty(NEW.dependsontask)) THEN
      RAISE EXCEPTION '@zssm_relation_dependsontask_required@';
    END IF;
    IF (isempty(NEW.c_projecttask_id)) THEN
      RAISE EXCEPTION '@zssm_relation_productionplan_task_required@';
    END IF;
    IF (NEW.dependsontask = NEW.c_projecttask_id) THEN
      RAISE EXCEPTION '@zssm_relation_noSelfJoin@';
    END IF;

    PERFORM zspm_projecttaskdep_circle(NEW.dependsontask, NEW.c_projecttask_id, v_tasklist);
   -- nur zur Programmentwicklung - Feld 'zspm_projecttaskdep.description' kann später wieder entfernt werden - MH 08.11.12
    v_description := COALESCE((SELECT wsv.name FROM zssm_workstep_v wsv WHERE wsv.c_projecttask_id = NEW.dependsontask), 'NEW.dependsontask ?');
    v_workstep_name := COALESCE((SELECT wsv.name FROM zssm_workstep_v wsv WHERE wsv.c_projecttask_id = NEW.c_projecttask_id), 'NEW.c_projecttask_id ?');
    v_description := v_description || ' - ' || v_workstep_name;
    NEW.description := COALESCE(v_description, '?-?');
  END IF;

  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
 END;

EXCEPTION
WHEN OTHERS THEN
  RAISE EXCEPTION '%', SQLERRM;
  IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW;
  END IF;
END;
$body$
LANGUAGE 'plpgsql';

SELECT zsse_droptrigger('zspm_projecttaskdep_taskdep_trg', 'zspm_projecttaskdep');
CREATE TRIGGER zspm_projecttaskdep_taskdep_trg
  BEFORE INSERT
  ON zspm_projecttaskdep FOR EACH ROW
  EXECUTE PROCEDURE public.zspm_projecttaskdep_taskdep_trg();

  
select zsse_DropFunction ('zssm_getproductionplanofproduct');
CREATE OR REPLACE FUNCTION zssm_getproductionplanofproduct(p_product character varying,p_org_id varchar)
  RETURNS SETOF zssm_productionplan_v AS
$BODY$
DECLARE
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2011 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************

Für Manuelles Auslösen benötigt.


*****************************************************/
v_cur record;
v_count numeric;
v_return varchar:='';
v_planexit_id varchar;
BEGIN
  -- 1. select all tasks with product AS output
  for v_cur in (select * from zssm_productionplan_task_v where m_product_id=p_product and assembly='Y' and isactive='Y' and ad_org_id=p_org_id
                                                               and exists (select 0 from c_project where isactive='Y' and projectstatus='OR' and c_project_id=zssm_productionplan_task_v.zssm_productionplan_v_id))
  LOOP
    select count(*) into v_count from zssm_productionplan_taskdep where c_project_id=v_cur.zssm_productionplan_v_id and dependsontask=v_cur.zssm_productionplan_task_id;
    if v_count>0 then -- There are following steps - Get the exit of plan and see if the desired Product is a Result of this Plan.
     select t.c_projecttask_id into v_planexit_id from zssm_productionplan_task t
                where t.c_project_id=v_cur.zssm_productionplan_v_id and not exists
                       (select 0 from zssm_productionplan_taskdep d where d.dependsontask=t.zssm_productionplan_task_id);
     select count(*)-1 into v_count from zspm_projecttaskbom b,c_projecttask t where t.c_projecttask_id=b.c_projecttask_id and t.assembly='N' and t.c_projecttask_id=v_planexit_id and b.m_product_id=p_product;
    end if;
    if v_count=0 then -- no other task depends on this one : it is an exit of the plan
       if v_return!= '' then
           v_return:=v_return||',';
       end if;
       v_return:=v_return||chr(39)||v_cur.zssm_productionplan_v_id||chr(39);
    end if;
  END LOOP;
  if v_return= '' then
     RETURN QUERY
     EXECUTE 'select * from zssm_productionplan_v where 1=0';
     RETURN;
     --return select * from zssm_productionplan_v where 1=0;
  else
     RETURN QUERY
     EXECUTE 'select * from zssm_productionplan_v where zssm_productionplan_v_id in ('||v_return||') order by isdefault desc,created';
     RETURN;
     --return select * from zssm_productionplan_v where zssm_productionplan_v_id in (v_return);
  end if;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
 

select zsse_DropFunction ('zssm_getworkstepandwarehouse');
CREATE OR REPLACE FUNCTION zssm_getworkstepandwarehouse(p_productid IN varchar,p_org_id in varchar,p_warehouse OUT varchar,p_planid OUT varchar,p_setuptime OUT numeric,p_timeperpiece OUT numeric,p_ad_org_id out varchar,
                                                        p_projecttask_id OUT varchar,p_mimimumqty OUT numeric,p_multipleofmimimumqty OUT varchar) RETURNS RECORD
AS $_$
DECLARE 
/***************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@openz.de)
First Published in 2013.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
Part of Manufactring. 

Computes the Time you need to produce an assembly in working - hours


*****************************************************/
p_workstepid varchar;
v_wsname varchar;
BEGIN
    /*
    select c_projecttask_id,zssm_productionplan_v_id into p_workstepid,p_planid from zssm_productionplan_task_v 
                                                         where m_product_id=p_productid and assembly='Y' and isactive='Y' 
                                                         and zssm_productionplan_v_id=zssm_getproductionplanIDofproduct(p_productid);
    */
    select pt.c_projecttask_id,p.c_project_id,l.m_warehouse_id,p.setuptime,p.timeperpiece,p.ad_org_id,pt.mimimumqty,pt.multipleofmimimumqty
           into p_workstepid,p_planid,p_warehouse ,p_setuptime,p_timeperpiece,p_ad_org_id,p_mimimumqty,p_multipleofmimimumqty
    from c_projecttask pt,c_project p ,m_locator l, zssm_productionplan_task tt where tt.c_project_id=p.c_project_id and tt.c_projecttask_id=pt.c_projecttask_id and l.m_locator_id=pt.receiving_locator and 
    p.projectcategory='PRP' and pt.m_product_id=p_productid and pt.assembly='Y' and pt.isactive='Y' 
                        and p.isactive='Y' and p.projectstatus='OR'  and p.isdefault='Y' and p.ad_org_id=p_org_id
                        order by p.created limit 1;
    if p_workstepid is  null then        
        RAISE exception '%', coalesce((select shortcut from ad_org where ad_org_id=p_org_id),'NO ORG!')||':@zssm_simulationnotpossibleworkstepundefined@'||zssi_getproductnamewithvalue(p_productid,'de_DE');
    end if;
    --select  w.m_warehouse_id,p.value into p_warehouse,v_wsname from c_projecttask p,m_locator w where p.c_projecttask_id=p_workstepid and w.m_locator_id=p.receiving_locator;
    if p_warehouse is null then
        RAISE exception '%', coalesce((select shortcut from ad_org where ad_org_id=p_org_id),'NO ORG!')||'@zssm_simulationnotpossiblelocatorundefined@'||coalesce(v_wsname,zssi_getproductnamewithvalue(p_productid,'de_DE')||' undefined');
    end if;
    RETURN;
END;
$_$  LANGUAGE 'plpgsql';


 
/*------| Get ending Worksteps of Production Order |-----------------------------------*\
	Input: Production Order ID (c_project_id)
	Output: Ending Work Steps (c_projecttask)
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zssm_getendingworksteps (p_project_id character varying)
RETURNS setof c_projecttask AS $BODY$
DECLARE
	v_return character varying := '';
	v_project_id character varying := '';
	v_projecttask record;
	v_count numeric;
BEGIN
	for v_projecttask in (select * from c_projecttask where c_projecttask.c_project_id = p_project_id)
	loop
		select count(*) into v_count
		from zspm_projecttaskdep
		where zspm_projecttaskdep.dependsontask = v_projecttask.c_projecttask_id;
		if v_count = 0 then
			if v_return != '' then
				v_return := v_return || ',';
			end if;
			v_return := v_return || chr(39) || v_projecttask.c_projecttask_id || chr(39);
		end if;
	end loop;
	if v_return= '' then
		RETURN QUERY
		EXECUTE 'select * from c_projecttask where 1=0';
		RETURN;
	else
		RETURN QUERY
		EXECUTE 'select * from c_projecttask where c_projecttask_id in ('||v_return||')';
		RETURN;
	end if;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Get ending Worksteps of Production Order |---------------------------------\*--

/*------| Get depending Worksteps of another Workstep |--------------------------------*\
	Input: Work Step ID (c_projecttask_id)
	Output: Depending Work Steps (c_projecttask)
	Condition: All Work Steps in same Production Order (c_project)
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zssm_getdependingworksteps (p_projecttask_id character varying)
RETURNS setof c_projecttask AS $BODY$
DECLARE
	v_return character varying := '';
	v_project_id character varying  := '';
	v_projecttask_id character varying := '';
	v_projecttask record;
	v_projecttaskdep record;
	v_count numeric;
BEGIN
	select c_project_id into v_project_id from c_projecttask where c_projecttask.c_projecttask_id = p_projecttask_id;
	for v_projecttask in (select * from c_projecttask where c_projecttask.c_project_id = v_project_id)
	loop
		for v_projecttaskdep in (select * from zspm_projecttaskdep where zspm_projecttaskdep.dependsontask = v_projecttask.c_projecttask_id and zspm_projecttaskdep.c_projecttask_id = p_projecttask_id)
		loop
			if v_return != '' then
				v_return := v_return || ',';
			end if;
			v_return := v_return || chr(39) || v_projecttaskdep.dependsontask || chr(39);
		end loop;
	end loop;
	if v_return= '' then
		RETURN QUERY
		EXECUTE 'select * from c_projecttask where 1=0';
		RETURN;
	else
		RETURN QUERY
		EXECUTE 'select * from c_projecttask where c_projecttask_id in ('||v_return||')';
		RETURN;
	end if;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Get depending Worksteps of another Workstep |------------------------------\*--

/*------| Get following Worksteps of another Workstep |--------------------------------*\
	Input: Work Step ID (c_projecttask_id)
	Output: Following Work Steps (c_projecttask)
	Condition: All Work Steps in same Production Order (c_project)
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zssm_getfollowingworksteps (p_projecttask_id character varying)
RETURNS setof c_projecttask AS $BODY$
DECLARE
	v_return character varying := '';
	v_project_id character varying  := '';
	v_projecttask_id character varying := '';
	v_projecttask record;
	v_projecttaskdep record;
	v_count numeric;
BEGIN
	select c_project_id into v_project_id from c_projecttask where c_projecttask.c_projecttask_id = p_projecttask_id;
	for v_projecttask in (select * from c_projecttask where c_projecttask.c_project_id = v_project_id)
	loop
		for v_projecttaskdep in (select * from zspm_projecttaskdep where zspm_projecttaskdep.dependsontask = p_projecttask_id and zspm_projecttaskdep.c_projecttask_id = v_projecttask.c_projecttask_id)
		loop
			if v_return != '' then
				v_return := v_return || ',';
			end if;
			v_return := v_return || chr(39) || v_projecttaskdep.c_projecttask_id || chr(39);
		end loop;
	end loop;
	if v_return= '' then
		RETURN QUERY
		EXECUTE 'select * from c_projecttask where 1=0';
		RETURN;
	else
		RETURN QUERY
		EXECUTE 'select * from c_projecttask where c_projecttask_id in ('||v_return||')';
		RETURN;
	end if;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Get following Worksteps of another Workstep |------------------------------\*--

/*------| Get Material Input of a Work Step |------------------------------------------*\
	Input: Work Step ID
	Output: List of Materials with Quantity
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zssm_getworkstepinput (p_projecttask_id character varying)
RETURNS setof zspm_projecttaskbom AS $BODY$
DECLARE
	v_projecttaskbom zspm_projecttaskbom%rowtype;
BEGIN
	for v_projecttaskbom in (select * from zspm_projecttaskbom where zspm_projecttaskbom.c_projecttask_id = p_projecttask_id)
	loop
		return next v_projecttaskbom;
	end loop;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Get Material Input of a Work Step |----------------------------------------\*--

/*------| Get Material Output of a Work Step |-----------------------------------------*\
	Input: Work Step ID
	Output: List of Materials with Quantity
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zssm_getworkstepoutput (p_projecttask_id character varying)
RETURNS setof zspm_projecttaskbom AS $BODY$
DECLARE
	v_projecttaskbom zspm_projecttaskbom%rowtype;
BEGIN
	if ((select assembly from c_projecttask where c_projecttask_id = p_projecttask_id) = 'N') then
		for v_projecttaskbom in (select * from zspm_projecttaskbom where zspm_projecttaskbom.c_projecttask_id = p_projecttask_id)
		loop
			return next v_projecttaskbom;
		end loop;
	elsif ((select m_product_id from c_projecttask where c_projecttask_id = p_projecttask_id) is not null) then
		select *
		into v_projecttaskbom
		from zspm_projecttaskbom
		where 1 = 0;
		v_projecttaskbom.quantity := (select qty from c_projecttask where c_projecttask_id = p_projecttask_id);
		v_projecttaskbom.m_product_id := (select m_product_id from c_projecttask where c_projecttask_id = p_projecttask_id);
		v_projecttaskbom.issuing_locator := (select issuing_locator from c_projecttask where c_projecttask_id = p_projecttask_id);
		v_projecttaskbom.receiving_locator := (select receiving_locator from c_projecttask where c_projecttask_id = p_projecttask_id);
		return next v_projecttaskbom;
	end if;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Get Material Output of a Work Step |---------------------------------------\*--


/*------| Generate Production Order BOMs |---------------------------------------------*\
	Input: Production Order ID, Quantity to produce in last Work Step
	Description:
	Last Work Step BOM is multiplied by quantity to produce.
	Depending Work Steps are multiplied recursive by maximum quantity of products in
	its BOMs used in following Work Step(s).
*/---------------------------------------------------------------------------------fw--\*

CREATE OR REPLACE FUNCTION zssm_generateproductionboms (
  p_project_id varchar,
  p_product_id varchar,
  p_qty numeric
)
RETURNS void AS
 -- SELECT zssm_generateproductionboms('31E625AAAAC94D0FB84BB847B7BAB343', '1DCDC4D7EC3A4963A14B52B8F559F5DA', 1);
 -- SELECT zssm_generateproductionboms(NULL, NULL, 0);
$body$
DECLARE
	v_workstep c_projecttask%rowtype;
	v_endingworkstep c_projecttask%rowtype;
	v_endingworkstep2 c_projecttask%rowtype;
	v_dependingworkstep c_projecttask%rowtype;
	v_followingworkstep c_projecttask%rowtype;
	v_workstepinput zspm_projecttaskbom%rowtype;
	v_workstepoutput zspm_projecttaskbom%rowtype;
	i numeric := 0;
	j numeric := 0;
	k numeric := 0;
	l numeric := 0;
	v_multiplicator numeric := 0;
  v_message VARCHAR := '';
BEGIN
  IF isempty(p_project_id) THEN 
    RAISE EXCEPTION 'Parameter p_project_id=%', COALESCE(p_project_id, 'NULL');    
  END IF;
  IF isempty(p_product_id) THEN 
    RAISE EXCEPTION 'Parameter p_product_id=%', COALESCE(p_product_id, 'NULL');    
  END IF;
  IF (p_qty IS NULL) THEN 
    RAISE EXCEPTION 'Parameter p_qty=%', COALESCE(p_qty, 'NULL');    
  END IF;
  IF (p_qty = 0) THEN 
    RAISE EXCEPTION 'Parameter p_qty=%', p_qty;    
  END IF;
	PERFORM zssm_setdeplevel(p_project_id);
	while exists (select * from c_projecttask where level = i and c_project_id = p_project_id)
	loop

		for v_workstep in (select * from c_projecttask where level = 0 and c_project_id = p_project_id)
		loop
                      if v_workstep.assembly='N' then
                            j := (select sum(quantity) from zssm_getworkstepoutput(v_workstep.c_projecttask_id) where m_product_id = p_product_id);
                      else
			select qty into j from c_projecttask where c_projecttask_id = v_workstep.c_projecttask_id;
                      end if;
                    IF (j IS NULL) OR (j = 0) THEN -- no qty found
                        v_message := '@Error@ >> Division by ZERO : select sum(quantity) from zssm_getworkstepoutput(''' || v_workstep.c_projecttask_id || ''') where m_product_id = ''' || p_product_id || ''' ';
                                RAISE EXCEPTION '%', v_message;
                    END IF;
			update c_projecttask set qty = round(qty * p_qty / j, 4), qty_temp = round(qty * p_qty / j, 4) where v_workstep.c_projecttask_id = c_projecttask.c_projecttask_id;
			j := 0;
		end loop;
		for v_workstep in (select * from c_projecttask where level = i and level != 0 and c_project_id = p_project_id)
		loop
		RAISE NOTICE 'Workstep: %', v_workstep.name;
			for v_workstepoutput in (select * from zssm_getworkstepoutput(v_workstep.c_projecttask_id))
			loop
			RAISE NOTICE '  Output: %, %', v_workstepoutput.quantity, v_workstepoutput.m_product_id;
				for v_followingworkstep in (select * from zssm_getfollowingworksteps(v_workstep.c_projecttask_id))
				loop
				RAISE NOTICE '    Following Workstep: %', v_followingworkstep.name;
					l := 0;
					for v_dependingworkstep in (select * from zssm_getdependingworksteps(v_followingworkstep.c_projecttask_id))
					loop
					RAISE NOTICE '      Depending Workstep: %', v_dependingworkstep.name;
						l := l + coalesce((select sum(quantity) from zssm_getworkstepoutput(v_dependingworkstep.c_projecttask_id) where m_product_id = v_workstepoutput.m_product_id), 0);
						RAISE NOTICE '      l: %', l;
					end loop;
					k := k + coalesce((select sum(quantity) from zssm_getworkstepinput(v_followingworkstep.c_projecttask_id) where m_product_id = v_workstepoutput.m_product_id), 0);
					RAISE NOTICE '    k: %', k;
				end loop;
				k := k / l;
				if k > j then
					j := k;
				end if;
			k := 0;
			end loop;
			update c_projecttask set qty_temp = qty * j where v_workstep.c_projecttask_id = c_projecttask.c_projecttask_id;
			j := 0;
		end loop;
    
   --  fire update-trigger zspm_projecttask_trg() to set zspm_projecttaskbom.quantity from qty';
		update c_projecttask set qty = round(qty_temp, 4) where level = i and c_project_id = p_project_id;
		i := i + 1;
	end loop;
EXCEPTION
WHEN OTHERS THEN
  v_message := 'SQL_PROC zssm_generateproductionboms(): ' || SQLERRM;
  RAISE EXCEPTION '%', v_message;
END;
$body$
LANGUAGE 'plpgsql';



/*------| Set Level of Dependencies of a Production Order |----------------------------*\
	Input: Production Order ID (c_project_id)
	Output: Void
	Description:
	Ending Work Steps -> Level 0
	Work Steps directly depending on Ending Work Steps -> Level 1
	etc.
*/---------------------------------------------------------------------------------fw--\*
CREATE OR REPLACE FUNCTION zssm_setdeplevel (p_project_id character varying)
RETURNS void AS $BODY$
DECLARE
	v_workstep c_projecttask%rowtype;
	v_endingworkstep c_projecttask%rowtype;
	v_dependingworkstep c_projecttask%rowtype;
	i integer := 0;
BEGIN
	for v_workstep in (select * from c_projecttask where c_project_id = p_project_id)
	loop
		update c_projecttask set level = null where v_workstep.c_projecttask_id = c_projecttask.c_projecttask_id;
	end loop;
	for v_endingworkstep in (select * from zssm_getendingworksteps(p_project_id))
	loop
		update c_projecttask set level = i where v_endingworkstep.c_projecttask_id = c_projecttask.c_projecttask_id;
	end loop;
	while exists (select * from c_projecttask where c_project_id = p_project_id and level = i )
	loop
		for v_workstep in (select * from c_projecttask where c_project_id = p_project_id and level = i)
		loop
			for v_dependingworkstep in (select * from zssm_getdependingworksteps(v_workstep.c_projecttask_id))
			loop
				update c_projecttask set level = i + 1 where v_dependingworkstep.c_projecttask_id = c_projecttask.c_projecttask_id;
			end loop;
		end loop;
		i := i + 1;
	end loop;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;
--*/----| Set Level of Dependencies of a Production Order |--------------------------\*--

/* 2012-11-29 MH new: view zssm_workstep_prp_v */
SELECT zsse_DropView ('zssm_workstep_prp_v');
CREATE OR REPLACE VIEW zssm_workstep_prp_v AS
SELECT
  c_projecttask_id AS zssm_workstep_prp_v_id,
  c_projecttask_id AS zssm_workstep_v_id,
  c_projecttask_id,
  ad_client_id,
  ad_org_id,
  isactive,
  created,
  createdby,
  updated,
  updatedby,
-- c_project_id AS zssm_productionorder_v_id,
-- zssm_productionplan_task_id,
  seqno,
  value,
  name,
  description,
  help,
  m_product_id,
  assembly,
  percentrejects,
  qty,
  issuing_locator,
  receiving_locator,
-- iscomplete,
-- iscommitceiling,
-- outsourcing,
-- taskbegun,
-- ismaterialdisposed,
-- istaskcancelled,
-- createbom,
-- planmaterial,
-- unplanmaterial,
-- canceltask,
-- begintask,
-- endtask,
  plannedcost,
  materialcostplan,
  indirectcostplan,
  machinecostplan,
  servcostplan,
  setuptime,
  timeperpiece,
  isautotriggered,
  isautogeneratedplan,
-- getmaterialfromstock,
-- gotopurchasing,
-- returnmaterialtostock
  startonlywithcompletematerial,
  forcematerialscan,
  mimimumqty,
  multipleofmimimumqty,
  c_color_id,
  isautocloseworkstep,
  createbom
FROM c_projecttask
WHERE c_project_id IS NULL;

CREATE OR REPLACE RULE zssm_workstep_prp_v_insert AS
ON INSERT TO zssm_workstep_prp_v DO INSTEAD
INSERT INTO c_projecttask (
	c_projecttask_id,
	ad_client_id,
	ad_org_id,
	isactive,
	created,
	createdby,
	updated,
	updatedby,
	seqno,
	name,
	description,
	help,
	m_product_id,
	qty,
 iscomplete,
 iscommitceiling,
	schedulestatus,
 outsourcing,
 taskbegun,
 ismaterialdisposed,
 istaskcancelled,
 createbom,
 planmaterial,
 unplanmaterial,
 canceltask,
 begintask,
 endtask,
  plannedcost,
	materialcostplan,
	indirectcostplan,
	machinecostplan,
	servcostplan,
 c_project_id,
 getmaterialfromstock,
 gotopurchasing,
 returnmaterialtostock,
	value,
	assembly,
  percentrejects,
	issuing_locator,
	receiving_locator,
  zssm_productionplan_task_id,
  startonlywithcompletematerial,
  forcematerialscan,
  setuptime,
  timeperpiece,
  isautotriggered,
  isautogeneratedplan,
  mimimumqty,
  multipleofmimimumqty,
  c_color_id,
  isautocloseworkstep
) VALUES (
	coalesce(NEW.zssm_workstep_v_id,NEW.zssm_workstep_prp_v_id),
	NEW.ad_client_id,
	NEW.ad_org_id,
	COALESCE(NEW.isactive,'Y'),
	COALESCE(NEW.created, now()),
	NEW.createdby,
	COALESCE(NEW.updated, now()),
	NEW.updatedby,
	NEW.seqno,
	NEW.name,
	NEW.description,
	NEW.help,
	NEW.m_product_id,
	COALESCE(NEW.qty, 1),
	'N', -- COALESCE(NEW.iscomplete, 'N'),
	'N', -- COALESCE(NEW.iscommitceiling, 'N'),
	'OK', -- COALESCE(NEW.schedulestatus, 'OK'),
	'N', -- COALESCE(NEW.outsourcing, 'N'),
	'N', -- COALESCE(NEW.taskbegun, 'N'),
  'N', -- COALESCE(NEW.ismaterialdisposed, 'N'),
  'N', -- COALESCE(NEW.istaskcancelled, 'N'),
  'N', -- COALESCE(NEW.createbom, 'N'),
  'N', -- COALESCE(NEW.planmaterial, 'N'),
  'N', -- COALESCE(NEW.unplanmaterial, 'N'),
  'N', -- COALESCE(NEW.canceltask, 'N'),
  'N', -- COALESCE(NEW.begintask, 'N'),
  'N', -- COALESCE(NEW.endtask, 'N'),
  NEW.plannedcost,
  NEW.materialcostplan,
	NEW.indirectcostplan,
	NEW.machinecostplan,
	NEW.servcostplan,
	NULL, -- NEW.zssm_productionorder_v_id,
  'N', -- COALESCE(NEW.getmaterialfromstock, 'N'),
  'N', -- COALESCE(NEW.gotopurchasing, 'N'),
  'N', -- COALESCE(NEW.returnmaterialtostock, 'N'),
	NEW.value,
	COALESCE(NEW.assembly, 'N'),
  NEW.percentrejects,
	NEW.issuing_locator,
	NEW.receiving_locator,
  NULL, -- NEW.zssm_productionplan_task_id
  COALESCE(NEW.startonlywithcompletematerial, 'N'),
  COALESCE(NEW.forcematerialscan, 'N'),
   COALESCE(NEW.setuptime,0),
   COALESCE(NEW.timeperpiece,0),
   NEW.isautotriggered,
   NEW.isautogeneratedplan,
   NEW.mimimumqty,
   coalesce(NEW.multipleofmimimumqty,'N'),
   NEW.c_color_id,
   coalesce(NEW.isautocloseworkstep,'N')
  );

CREATE OR REPLACE RULE zssm_workstep_prp_v_update AS
ON UPDATE TO zssm_workstep_prp_v DO INSTEAD
UPDATE c_projecttask SET
	c_projecttask_id = NEW.zssm_workstep_prp_v_id,
	ad_client_id = NEW.ad_client_id,
	ad_org_id = NEW.ad_org_id,
	isactive = NEW.isactive,
	created = NEW.created,
	createdby = NEW.createdby,
	updated = NEW.updated,
	updatedby = NEW.updatedby,
	seqno = NEW.seqno,
	name = NEW.name,
	description = NEW.description,
	help = NEW.help,
	m_product_id = NEW.m_product_id,
	qty = NEW.qty,
-- iscomplete = NEW.iscomplete,
-- iscommitceiling = NEW.iscommitceiling,
-- schedulestatus = NEW.schedulestatus,
-- outsourcing = NEW.outsourcing,
-- taskbegun = NEW.taskbegun,
-- ismaterialdisposed = NEW.ismaterialdisposed,
-- istaskcancelled = NEW.istaskcancelled,
-- createbom = NEW.createbom,
-- planmaterial = NEW.planmaterial,
-- unplanmaterial = NEW.unplanmaterial,
-- canceltask = NEW.canceltask,
-- begintask = NEW.begintask,
-- endtask = NEW.endtask,
  plannedcost = NEW.plannedcost,
	materialcostplan = NEW.materialcostplan,
	indirectcostplan = NEW.indirectcostplan,
	machinecostplan = NEW.machinecostplan,
	servcostplan = NEW.servcostplan,
-- c_project_id = NEW.zssm_productionorder_v_id,
-- getmaterialfromstock = NEW.getmaterialfromstock,
-- gotopurchasing = NEW.gotopurchasing,
-- returnmaterialtostock = NEW.returnmaterialtostock,
	value = NEW.value,
	assembly = NEW.assembly,
  percentrejects = NEW.percentrejects,
	issuing_locator = NEW.issuing_locator,
	receiving_locator = NEW.receiving_locator,
-- zssm_productionplan_task_id = NEW.zssm_productionplan_task_id
  startonlywithcompletematerial = NEW.startonlywithcompletematerial,
  forcematerialscan = NEW.forcematerialscan,
  setuptime=COALESCE(NEW.setuptime,0),
  timeperpiece= COALESCE(NEW.timeperpiece,0),
  isautotriggered=NEW.isautotriggered,
  isautogeneratedplan=NEW.isautogeneratedplan,
  mimimumqty=NEW.mimimumqty,
  multipleofmimimumqty=new.multipleofmimimumqty,
  c_color_id = NEW.c_color_id,
  isautocloseworkstep=coalesce(NEW.isautocloseworkstep,'N')
WHERE
	c_projecttask_id = NEW.c_projecttask_id;

CREATE OR REPLACE RULE zssm_workstep_prp_v_delete AS
 ON DELETE TO zssm_workstep_prp_v DO INSTEAD (
    --DELETE FROM zssm_workstepactivities_v WHERE zssm_workstep_prp_v_id= old.c_projecttask_id;
    --DELETE FROM zssm_WorkstepTechDoc_v WHERE zssm_workstep_prp_v_id= old.c_projecttask_id;
    --DELETE FROM  zssm_workstepmachines_v WHERE zssm_workstep_prp_v_id= old.c_projecttask_id;
   -- DELETE FROM  zssm_workstepbom_v WHERE zssm_workstep_prp_v_id= old.c_projecttask_id;
    DELETE FROM c_projecttask WHERE c_projecttask_id = old.c_projecttask_id;
);

	
-- View to show all quantities ordered, but not needed anymore
 -- Movet to here because of cross-script dependencies.
select zsse_DropView ('mrp_production_unneeded');
create view mrp_production_unneeded as
        select mrp_production_unneeded_id,created,createdby,updated,updatedby,isactive,ad_client_id,ad_org_id,
               line,dateordered,datepromised,m_product_id,qtyordered,qtydelivered,
               c_project_id,c_projecttask_id ,description,
               qtyonhand, qtyinflow,qtyoutflow,unnededqty ,order_min,qtyoptimal,value
        from (
                        select ol.c_projecttask_id as mrp_production_unneeded_id,ol.created,ol.createdby,ol.updated,ol.updatedby,ol.isactive,ol.ad_client_id,ol.ad_org_id,
                               ol.seqno as line,trunc(ol.created) as dateordered,ol.enddate as datepromised,ol.m_product_id,ol.qty as qtyordered,ol.qtyproduced as qtydelivered,ol.qtyleft,
                               ol.c_projecttask_id ,ol.description,ol. zssm_productionorder_v_id as c_project_id,
                               coalesce(ov.qtyonhand,0) as qtyonhand, coalesce(ov.qtyinflow,0) as qtyinflow, coalesce(ov.qtyoutflow,0) as qtyoutflow,  p.value,
                               (select max(coalesce(mimimumqty,1))  from c_projecttask where assembly='Y' and m_product_id=ol.m_product_id and c_project_id is null) as order_min,
                               coalesce(sum(og.qtyoptimal),0)  as qtyoptimal,
                               (coalesce(ov.qtyinflow,0) + coalesce(ov.qtyonhand,0)) - 
                                ( coalesce(ov.qtyoutflow,0)  + coalesce(sum(og.qtyoptimal),0)  
                                + case when (select max(coalesce(mimimumqty,0)) from c_projecttask where assembly='Y' and m_product_id=ol.m_product_id and c_project_id is null)>0 
                                                          and ( (coalesce(ov.qtyinflow,0) + coalesce(ov.qtyonhand,0)) - ( coalesce(ov.qtyoutflow,0)  + coalesce(sum(og.qtyoptimal),0)) )    <  
                                                          (select max(coalesce(mimimumqty,0)) from c_projecttask where assembly='Y' and m_product_id=ol.m_product_id and c_project_id is null) then 9999999999   else 0 end ) as unnededqty                     
                        from  zssm_workstep_v ol        left join m_product_org og on og.ad_org_id=ol.ad_org_id and og.m_product_id=ol.m_product_id and og.isactive='Y'
                                                                                                                 and og.m_locator_id in (select m_locator_id from m_locator where m_warehouse_id in (select m_warehouse_id from m_warehouse where ad_org_id=ol.ad_org_id) )
                                                                                   left join zssi_onhanqty_overview ov on  ov.m_warehouse_id in (select m_warehouse_id from m_warehouse where ad_org_id=ol.ad_org_id) 
                                                                                                                 and ov.m_product_id=ol.m_product_id ,
                                     m_product p
                        where ol.m_product_id=p.m_product_id  and ol.iscomplete='N' and  ol.istaskcancelled='N'  and ol.qtyleft>0 
                        group by
                        ol.c_projecttask_id,ol.created,ol.createdby,ol.updated,ol.updatedby,ol.isactive,ol.ad_client_id,ol.ad_org_id,
                              ol.seqno,ol.enddate,ol.m_product_id,ol.qty,ol.qtyproduced,ol.description,ol.qtyleft,ol. zssm_productionorder_v_id,
                               ov.qtyonhand, ov.qtyinflow,ov.qtyoutflow,ov.qtyincomming ,  ov.qtyordered,ov.qtyreserved , ov.qtyinsale,
                              p.value
        ) a where unnededqty > 0 and not exists (select 0 from mrp_inoutplan_v v where v.m_product_id=a.m_product_id and v.estimated_stock_qty<=a.order_min and v.planneddate=a.datepromised and v.m_warehouse_id in (select m_warehouse_id from m_warehouse where ad_org_id=a.ad_org_id) );
                               

                               
/* serialproduction.sql */
CREATE OR REPLACE FUNCTION zssm_checkmatampel (p_project_id character varying)
RETURNS varchar AS $BODY$
DECLARE
    v_task varchar;
    v_begun varchar;
    v_qty numeric;
    v_avail numeric;
    v_imageIdRed varchar:='FF8081816D63610B016D63812D330RED';
    v_imageIdYellow varchar:='FF8081816D63610B016D638145YELLOW';
    v_imageIdGreen varchar:='FF8081816D63610B016D63816A5GREEN';
    v_stock numeric;
    v_date timestamp without time zone;
    v_cur record;
    v_return varchar:=v_imageIdGreen;
BEGIN
    select c_projecttask_id,taskbegun into v_task,v_begun from c_projecttask where  c_project_id=p_project_id limit 1;
    if v_task is null then
        select c_projecttask_id,taskbegun into v_task,v_begun from c_projecttask where c_projecttask_id=p_project_id;
    end if;
    if v_task is not null then
        if v_begun='Y' then
            -- Begonnene Tasks: Grün, wennn Mat komplett erhalten, Gelb, wenn (Rest)-Material am Lager, Rot, wenn Material nicht am Lager 
            for v_cur in (select quantity-qtyreceived as qty,qty_instock as avail from zssm_Workstepbom_V where quantity-qtyreceived>0 and zssm_Workstep_V_id=v_task)
            LOOP
                if v_cur.qty>0 and v_cur.avail>=v_cur.qty  then
                    v_return := v_imageIdYellow;
                end if;
                if v_cur.qty>0 and v_cur.avail<v_cur.qty then
                    return v_imageIdRed;
                end if;
            END LOOP;
        else
             /*
             Geplante Tasks: Gelb, wenn Bedarfsdatum in der Zukunft und Materialbedarf über die voraussichtlich verfügbare Menge gedeckt werden kann, die aktuelle Lagermenge aber nicht für den Bedarf ausreicht.
                             Grün, wenn  Materialbedarf über die vorhandene Lager - Menge gedeckt werden kann und das Material auch verfügbar ist 
                             Rot,  wenn Materialbedarf nicht gedeckt werden kann.
            */
            for v_cur in (select quantity,qty_available,qty_instock,date_plan from zssm_Workstepbom_V where  zssm_Workstep_V_id=v_task)
            LOOP
                if coalesce(v_cur.date_plan,trunc(now()))<=trunc(now()) then
                    if v_cur.quantity>v_cur.qty_instock then
                        return v_imageIdRed;
                    end if;
                else
                    if v_cur.quantity<=v_cur.qty_available and v_cur.quantity>v_cur.qty_instock then
                        v_return:= v_imageIdYellow;
                    end if;
                    if v_cur.quantity>v_cur.qty_available then
                        return v_imageIdRed;
                    end if;
                end if;
            END LOOP;
        end if;
    end if;
    return v_return;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE COST 100;


SELECT zsse_DropView ('zssm_productionorderstatus_v');
CREATE OR REPLACE VIEW zssm_productionorderstatus_v AS
SELECT v.*,zssm_checkmatampel (v.zssm_productionorder_v_id) as image,v.zssm_productionorder_v_id as zssm_productionorderstatus_v_id from    zssm_productionorder_v  v where v.isactive = 'Y' AND v.projectstatus <> 'CL';

SELECT zsse_DropView ('zssm_workstepstatusplan_v');
CREATE OR REPLACE VIEW zssm_workstepstatusplan_v AS
SELECT v.*,zssm_checkmatampel (v.zssm_workstep_v_id) as image,v.zssm_workstep_v_id as zssm_workstepstatusplan_v_id from    zssm_workstep_v  v where v.iscomplete ='N'  and v.assembly='Y' and v.istaskcancelled='N' and v.taskbegun ='N' and v.zssm_productionorder_v_id is not null and exists (select 0 from c_project where v.zssm_productionorder_v_id =c_project.c_project_id and c_project.projectstatus='OR');

SELECT zsse_DropView ('zssm_workstepstatusactive_v');
CREATE OR REPLACE VIEW zssm_workstepstatusactive_v AS
SELECT v.*,zssm_checkmatampel (v.zssm_workstep_v_id) as image,v.zssm_workstep_v_id as zssm_workstepstatusactive_v_id from    zssm_workstep_v  v where v.iscomplete ='N'  and v.assembly='Y' and v.istaskcancelled='N' and v.taskbegun ='Y' and v.zssm_productionorder_v_id is not null;
