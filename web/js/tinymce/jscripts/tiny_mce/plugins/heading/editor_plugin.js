/**
 *
 * @author WSL.RU
 * @copyright Copyright (c) 2006-2009. All rights reserved.
 *
 */

(function(tinymce) {

    /**
     * Add a new command to tiny MCE
     */
    function addCommand(ed, url, headingNumber) {
        var headingTag = 'h' + headingNumber;

        ed.addButton(headingTag, {
            title : ed.getLang('advanced.' + headingTag, headingTag) + ' (Ctrl+' + headingNumber + ')',
            image : url + '/img/' + headingTag + '.gif',
            cmd: 'mceHeading' + headingNumber
        });

        ed.addCommand('mceHeading' + headingNumber, function() {
            var ct = ed.getParam("heading_clear_tag", false) ? ed.getParam("heading_clear_tag", "") : "";

            if (ed.selection.getNode().nodeName.toLowerCase() != headingTag) {
                ct = headingTag;
            }

            ed.execCommand('FormatBlock', false, ct)
        });

        ed.onNodeChange.add( function(ed, cm, n) {
            cm.setActive(headingTag, n.nodeName.toLowerCase() == headingTag);
        });
    }

    tinymce.create('tinymce.plugins.heading', {
        /**
         * Initialize the plugin
         */
        init : function(ed, url) {
            for (var headingNumber = 1; headingNumber <= 6; headingNumber++) {
                addCommand(ed, url, headingNumber);
            }
        },

        /**
         * Plugin information
         */
        getInfo : function() {
            return {
                longname :  'Heading plugin',
                author :    'WSL.RU / Andrey G, ggoodd, Merten van Gerven',
                authorurl : 'http://wsl.ru',
                infourl :   'mailto:merten.vg@gmail.com',
                version :   '1.4'
            };
        }
    });

    tinymce.PluginManager.add('heading', tinymce.plugins.heading);

})(tinymce);