package org.openbravo.erpCommon.info;

import org.openbravo.base.secureApp.VariablesSecureApp;


// VariablesSecureApp.SessionValues are replaced by this class
public class SearchVariablesBuilder {

  // public Attributes
  private String _KeySearch = "%";
  private String _NameSearch = "";
  private String _FocusedField = "";
  private boolean _IsSearchByKey = true;

  // private Attributes
  private String _KeyContext = "";
  private String _NameContext = "";
  
  // static Strings
  private final static String _ParamKey = "paramKey";
  private final static String _ParamName = "paramName";


  public String getKeySearch() { return _KeySearch; }
  public String getNameSearch() { return _NameSearch; }
  public String getFocusedField() { return _FocusedField; }
  public boolean isSearchByKey() { return _IsSearchByKey; }


  public SearchVariablesBuilder(
		  VariablesSecureApp vars,
		  String contextPrefix,
		  String searchValue,
		  int valuesFound,
		  int namesFound) {

	  setPrivateAttributes(contextPrefix);
	  setPublicAttributes(vars, searchValue, valuesFound, namesFound);
  }
  
  private void setPrivateAttributes(String contextPrefix) {
	  
	  _KeyContext = contextPrefix + ".key";
	  _NameContext = contextPrefix + ".name";
  }
  
  private void setPublicAttributes(
		  VariablesSecureApp vars,
		  String searchValue,
		  int valuesFound,
		  int namesFound) {
	  

	if (valuesFound > 0) {
		replaceNameWithKey(vars, searchValue);

	} else if (namesFound > 0) {
		replaceKeyWithName(vars, searchValue);

	} else {
		replaceKeyWithKey(vars, searchValue);
	}
	
	setSessionVariables(vars);
  }

  private void replaceNameWithKey(VariablesSecureApp vars, String searchValue) {

	replaceSessionValue(vars, _NameContext, _KeyContext, searchValue);
	_KeySearch = searchValue;
	_FocusedField = _ParamKey;
  }

  private void replaceSessionValue(
		  VariablesSecureApp vars,
		  String varToReplace,
		  String varReplacement,
		  String varValueReplacement) {
	  
	vars.removeSessionValue(varToReplace);
	vars.setSessionValue(varReplacement, varValueReplacement);
  }
  
  private void replaceKeyWithName(VariablesSecureApp vars, String searchValue) {
	  
	replaceSessionValue(vars, _KeyContext, _NameContext, searchValue);
	_NameSearch = searchValue;
	_FocusedField = _ParamName;
	_IsSearchByKey = false;
  }

  private void replaceKeyWithKey(VariablesSecureApp vars, String searchValue) {

	replaceSessionValue(vars, _KeyContext, _KeyContext, searchValue);
	_KeySearch = searchValue;
	_FocusedField = _ParamKey;
  }
  
  private void setSessionVariables(VariablesSecureApp vars) {

	  vars.setSessionValue("Project.key", _KeySearch);
	  vars.setSessionValue("Project.name", _NameSearch);
  }
}
