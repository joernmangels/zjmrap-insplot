@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Upload Log'

@UI.headerInfo: {
  typeName:       'Log Entry',
  typeNamePlural: 'Log Entries',
  title:          { type: #STANDARD, value: 'Message' },
  description:    { type: #STANDARD, value: 'ProtTimestamp' }
}

define view entity ZJMQMI_C_INSPLOT_PROT
  as projection on ZJMQMI_I_INSPLOT_PROT
{
  @UI.facet: [
    { id: 'Header',   type: #COLLECTION,          label: 'Log Entry', position: 10 },
    { id: 'General',  type: #FIELDGROUP_REFERENCE, targetQualifier: 'General',
      parentId: 'Header', label: 'Details',        position: 10 }
  ]

  key InspectionLot,
  key ProtGuid,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 10, label: 'Timestamp' }],
         identification:  [{ position: 10, label: 'Timestamp' }],
         fieldGroup:      [{ qualifier: 'General',    position: 10, label: 'Timestamp' }] }
  ProtTimestamp,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 20, label: 'File Name' }],
         identification:  [{ position: 20, label: 'File Name' }],
         fieldGroup:      [{ qualifier: 'General',    position: 20, label: 'File Name' }] }
  FileName,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 30, label: 'Row' }],
         fieldGroup:      [{ qualifier: 'General',    position: 30, label: 'Row' }] }
  RowNumber,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 40, label: 'Insp. Operation' }],
         fieldGroup:      [{ qualifier: 'General',    position: 40, label: 'Insp. Operation' }] }
  InspectionOperation,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 45, label: 'Characteristic' }],
         fieldGroup:      [{ qualifier: 'General',    position: 45, label: 'Characteristic' }] }
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

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 60, label: 'Message' }],
         identification:  [{ position: 60, label: 'Message' }],
         fieldGroup:      [{ qualifier: 'General',    position: 60, label: 'Message' }] }
  Message,

  @UI: { lineItem:        [{ qualifier: 'Protokoll',  position: 70, label: 'Created By' }],
         fieldGroup:      [{ qualifier: 'General',    position: 70, label: 'Created By' }] }
  CreatedBy,

  @UI.fieldGroup: [{ qualifier: 'General', position: 80, label: 'Created On' }]
  CreatedAt,

  _InspectionLot : redirected to parent ZJMQMI_C_INSPLOT
}
