package org.openz.view.templates;
/*
****************************************************************************************************************************************************
The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/MPL-1.1.html
Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
License for the specific language governing rights and limitations under the License.
The Original Code is OpenZ. The Initial Developer of the Original Code is Stefan Zimmermann (sz@zimmermann-software.de)
Copyright (C) 2022 Stefan Zimmermann All Rights Reserved.
Contributor(s): ______________________________________.
***************************************************************************************************************************************************
*/
import java.net.URI;
import java.net.URL;

import org.openbravo.utils.Replace;
import org.openz.util.FileUtils;
import org.openbravo.base.secureApp.HttpSecureAppServlet;
import org.openbravo.base.secureApp.VariablesSecureApp;

public class ConfigureIframe{

    public static StringBuilder doConfigure(HttpSecureAppServlet servlet,VariablesSecureApp vars,String iframename,int colspan,int height,String url) throws Exception {
        StringBuilder retval= new StringBuilder();

        final String directory= servlet.strBasePath;
        Object template =  servlet.getServletContext().getAttribute("iframeTEMPLATE");
        if (template==null) {
          template = new String(FileUtils.readFile("Iframe.xml", directory + "/src-loc/design/org/openz/view/templates/"));
          servlet.getServletContext().setAttribute("iframeTEMPLATE", template);
        }
        retval.append(template.toString());

        Replace.replace(retval, "@NAME@", iframename);
        Replace.replace(retval, "@NUMCOLS@", Integer.toString(colspan));
        Replace.replace(retval, "@HEIGHT@", Integer.toString(height));

        //enoding of the uri
        URL url2= new URL(url);
        URI uri = new URI(url2.getProtocol(), url2.getUserInfo(), url2.getHost(), url2.getPort(), url2.getPath(), url2.getQuery(), url2.getRef());
        url = uri.toASCIIString();
        Replace.replace(retval, "@URL@", url);

        return retval;
    }

}
