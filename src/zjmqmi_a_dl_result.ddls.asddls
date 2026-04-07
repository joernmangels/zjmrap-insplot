@EndUserText.label: 'Download-Ergebnis: Download-URL'
define abstract entity ZJMQMI_A_DL_RESULT
{
  @EndUserText.label: 'Download-Link'
  DownloadUrl : abap.char(200);

  @EndUserText.label: 'Dateiname'
  FileName    : abap.char(255);
}
