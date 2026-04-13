@EndUserText.label: 'Upload-Parameter: Prüfergebnisse'
define abstract entity ZJMQMI_A_UPLOAD
{
  FileName    : abap.char(255);
  FileContent : abap.rawstring(0);
  MimeType    : abap.char(100);
}
