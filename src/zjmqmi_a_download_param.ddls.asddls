@EndUserText.label: 'Download Parameter'
define abstract entity ZJMQMI_A_DOWNLOAD_PARAM
{
  @EndUserText.label: 'Dateiname (ohne Endung)'
  @UI.defaultValue: 'Prueflose'
  DownloadFileName : abap.char(255);

  @EndUserText.label: 'Weitere Prüflose (kommagetrennt)'
  AdditionalLots   : abap.char(500);
}
