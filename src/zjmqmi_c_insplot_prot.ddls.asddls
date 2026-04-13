@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Upload-Protokoll'
define view entity ZJMQMI_C_INSPLOT_PROT
  as projection on ZJMQMI_I_INSPLOT_PROT
{
  key InspectionLot,
  key ProtGuid,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 10, label: 'Zeitstempel' }]
  ProtTimestamp,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 20, label: 'Dateiname' }]
  FileName,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 30, label: 'Zeile' }]
  RowNumber,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 40, label: 'Prüfvorgang' }]
  InspectionOperation,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 45, label: 'Prüfmerkmal' }]
  InspectionCharacteristic,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 50, label: 'Status',
                   criticality: 'Status',
                   criticalityRepresentation: #WITH_ICON }]
  Status,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 60, label: 'Meldung' }]
  Message,

  @UI.lineItem: [{ qualifier: 'Protokoll', position: 70, label: 'Erstellt von' }]
  CreatedBy,

  CreatedAt,
  _InspectionLot : redirected to parent ZJMQMI_C_INSPLOT
}
