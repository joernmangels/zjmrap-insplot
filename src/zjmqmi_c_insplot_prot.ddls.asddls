@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Upload-Protokoll'

@UI.headerInfo: {
  typeName:       'Protokolleintrag',
  typeNamePlural: 'Protokolleinträge',
  title:          { type: #STANDARD, value: 'Message' },
  description:    { type: #STANDARD, value: 'ProtTimestamp' }
}

define view entity ZJMQMI_C_INSPLOT_PROT
  as projection on ZJMQMI_I_INSPLOT_PROT
{
  @UI.facet: [
    { id: 'Header',   type: #COLLECTION,          label: 'Protokolleintrag', position: 10 },
    { id: 'General',  type: #FIELDGROUP_REFERENCE, targetQualifier: 'General',
      parentId: 'Header', label: 'Details',          position: 10 }
  ]

  key InspectionLot,
  key ProtGuid,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 10, label: 'Zeitstempel' }],
         identification:  [{ position: 10, label: 'Zeitstempel' }],
         fieldGroup:      [{ qualifier: 'General',    position: 10, label: 'Zeitstempel' }] }
  ProtTimestamp,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 20, label: 'Dateiname' }],
         identification:  [{ position: 20, label: 'Dateiname' }],
         fieldGroup:      [{ qualifier: 'General',    position: 20, label: 'Dateiname' }] }
  FileName,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 30, label: 'Zeile' }],
         fieldGroup:      [{ qualifier: 'General',    position: 30, label: 'Zeile' }] }
  RowNumber,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 40, label: 'Prüfvorgang' }],
         fieldGroup:      [{ qualifier: 'General',    position: 40, label: 'Prüfvorgang' }] }
  InspectionOperation,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 45, label: 'Prüfmerkmal' }],
         fieldGroup:      [{ qualifier: 'General',    position: 45, label: 'Prüfmerkmal' }] }
  InspectionCharacteristic,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 50, label: 'Status',
                              criticality: 'Status',
                              criticalityRepresentation: #WITH_ICON }],
         identification:  [{ position: 50, label: 'Status',
                              criticality: 'Status',
                              criticalityRepresentation: #WITH_ICON }],
         fieldGroup:      [{ qualifier: 'General',    position: 50, label: 'Status',
                              criticality: 'Status',
                              criticalityRepresentation: #WITH_ICON }] }
  Status,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 60, label: 'Meldung' }],
         identification:  [{ position: 60, label: 'Meldung' }],
         fieldGroup:      [{ qualifier: 'General',    position: 60, label: 'Meldung' }] }
  Message,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 70, label: 'Erstellt von' }],
         fieldGroup:      [{ qualifier: 'General',    position: 70, label: 'Erstellt von' }] }
  CreatedBy,

  @UI.fieldGroup: [{ qualifier: 'General', position: 80, label: 'Erstellt am' }]
  CreatedAt,

  _InspectionLot : redirected to parent ZJMQMI_C_INSPLOT
}
