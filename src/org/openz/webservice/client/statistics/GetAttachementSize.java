package org.openz.webservice.client.statistics;

import java.io.File;

import org.openbravo.base.session.OBPropertiesProvider;
import org.openbravo.database.ConnectionProvider;

public class GetAttachementSize {

    /*
     * Gibt die Größe der Anhänge einer bestimmten Ord (oder allen, wenn Org leer)
     * in Bytes zurück. Die Dateigröße wird dabei für spätere Abfragen in den
     * Tabellen c_file und c_filedeleted gespeichert.
     */
    public static Long getAttachementSize(String orgid, ConnectionProvider conn) throws Exception {

        GetAttachementSizeData[] newFiles = GetAttachementSizeData.select(conn, orgid);

        // update new files with filesize
        final String fileDir = OBPropertiesProvider.getInstance().getOpenbravoProperties().getProperty("attach.path");
        for (GetAttachementSizeData data : newFiles) {
            final String filePath = fileDir + "/" + data.adTableId + "-" + data.adRecordId + "/" + data.name;

            File file = new File(filePath);
            if (file.exists()) {
                GetAttachementSizeData.updateFilesize(conn, Long.toString(file.length()), data.cFileId);
            } else {
                // file not found
                GetAttachementSizeData.updateFilesize(conn, "0", data.cFileId);
            }
        }

        final Long result = Long.parseLong(GetAttachementSizeData.selectFilesize(conn, orgid))
                + Long.parseLong(GetAttachementSizeData.selectFilesizeDeleted(conn, orgid));

        return result;
    }
}
