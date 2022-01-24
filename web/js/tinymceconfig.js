tinyMCE.init({
        mode : "textareas",
        theme : "simple",
        editor_selector : "EditorSimple",
                inline_styles: false,
        formats: {
        underline: { inline: 'u', exact : true }
        },
        width : "900"
});

tinyMCE.init({
        mode : "textareas",
        theme : "simple",
        readonly : 1,
        editor_selector : "EditorReadonly",
                inline_styles: false,
        formats: {
        underline: { inline: 'u', exact : true }
        },
        width : "900"
});

function HandleMCEEvent(e) {
        if (e.type=="keyup"){
           setWindowEditing(true);logChanges(this);return true;         
        }
        if (e.type=="onpaste"){
           setWindowEditing(true);logChanges(this);return true;         
        }
                if (e.type=="onmouseout"){
           setWindowEditing(true);logChanges(this);return true;         
        }
                        if (e.type=="onchange"){
           setWindowEditing(true);logChanges(this);return true;         
        }
        return true; // Continue handling
}

tinyMCE.init({
        
        editor_selector : "EditorAdvanced",
        width : "900",

        mode : "textareas",
        theme : "advanced",
        plugins : "emotions,spellchecker,advhr,insertdatetime,preview,heading,fullscreen", 
        extended_valid_elements : "iframe[src|frameborder|style|scrolling|class|width|height|name|align]",
        heading_clear_tag : "", 
        forced_root_block : "",
        cleanup_on_startup: false,
        trim_span_elements: false,
        verify_html: false,
        cleanup: false,
        convert_urls: false,
        force_p_newlines : false,
        force_br_newlines : false,
        // Theme options - button# indicated the row# only
        theme_advanced_buttons1 : "h1,h2,h3,|,bold,italic,underline,|,justifyleft,justifycenter,justifyright,fontselect,fontsizeselect",
        theme_advanced_buttons2 : "cut,copy,paste,|,bullist,numlist,|,outdent,indent,|,undo,redo,|,link,unlink,anchor,image,|,code,preview,|,forecolor,backcolor",
        theme_advanced_buttons3 : "insertdate,inserttime,|,spellchecker,advhr,,removeformat,|,sub,sup,|,charmap,emotions,|,fullscreen",      
        theme_advanced_toolbar_location : "top",
        theme_advanced_toolbar_align : "left",
        theme_advanced_statusbar_location : "bottom",
        theme_advanced_resizing : true,
        handle_event_callback :  "HandleMCEEvent",
        entity_encoding : "raw",     
        inline_styles: false,
        formats: {
        underline: { inline: 'u', exact : true }
        },
        onchange_callback:  "HandleMCEEvent",

	setup : function(ed) {

		// isn't called -- test this here http://fiddle.tinymce.com/zBfaab
		//ed.onChange.add(function(ed, l) { 
		//      console.debug('Editor contents was modified. Contents: ' + l.content);
			
		//	l.content = l.content.replace(/(<)(.)/g, '$1 $2');		
		//	l.content = l.content.replace(/[\x00-\x1F\x7F]/g, '');		
		//});

		// Needed for html source view. -- wenn abgerufen ist  schon in ein &lt konvertiert
		ed.onGetContent.add(function(ed, o) {
		//	o.content = o.content.replace(iframePattern, iframeReplacePattern);
		//	o.content = o.content.replace(iframePattern, iframeReplacePattern);
			
			o.content = o.content.replace(/(&lt;)(.)/g, '$1 $2');
			o.content = o.content.replace(/(&gt;)(.)/g, '$1 $2');
			o.content = o.content.replace(/[\x00-\x1F\x7F]/g, '');
		});
		
		// isn't called -- test this here http://fiddle.tinymce.com/zBfaab
		// ed.onPaste.add(function(ed, e) {
		//	e.content = e.content.replace(/(<)(.)/g, '$1 $2');
		//	e.content = e.content.replace(/[\x00-\x1F\x7F]/g, '');			
		// });					

       		ed.onSaveContent.add(function(ed, o) {
			o.content = o.content.replace(/(&lt;)(.)/g, '$1 $2');
			o.content = o.content.replace(/(&gt;)(.)/g, '$1 $2');
			o.content = o.content.replace(/[\x00-\x1F\x7F]/g, '');	        
		});	
	}
}); 
