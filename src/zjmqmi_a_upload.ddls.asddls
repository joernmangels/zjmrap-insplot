@EndUserText.label: 'Upload-Parameter: Prüfergebnisse'
define abstract entity ZJMQMI_A_UPLOAD
{
  @EndUserText.label: 'Dateiname'
  FileName    : abap.char(255);

  @EndUserText.label: 'Datei (Excel)'
  @Semantics.largeObject: {
    mimeType:    'MimeType',
    fileName:    'FileName',
    acceptableMimeTypes: [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel'
    ],
    contentDispositionPreference: #ATTACHMENT
  }
  FileContent : abap.rawstring(0);

  @EndUserText.label: 'MIME-Typ'
  @UI.hidden: true
  MimeType    : abap.char(100);
}
