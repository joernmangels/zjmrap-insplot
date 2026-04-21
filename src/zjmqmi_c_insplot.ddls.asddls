@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Inspection Lots'
@Search.searchable: false
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName:       'Inspection Lot',
  typeNamePlural: 'Inspection Lots',
  title:          { type: #STANDARD, value: 'InspectionLot' },
  description:    { type: #STANDARD, value: 'InspectionLotText' }
}   

define root view entity ZJMQMI_C_INSPLOT
  provider contract transactional_query
  as projection on ZJMQMI_I_INSPLOT
{
  @UI.facet: [
    { id: 'Header',     type: #COLLECTION,          label: 'General',        position: 10 },
    { id: 'General',    type: #FIELDGROUP_REFERENCE, targetQualifier: 'General',
      parentId: 'Header', label: 'Master Data',       position: 10 },
    { id: 'DlUlStatus', type: #FIELDGROUP_REFERENCE, targetQualifier: 'DlUlStatus',
      parentId: 'Header', label: 'Download/Upload',   position: 20 },
    { id: 'Merkmale',   type: #LINEITEM_REFERENCE,
      targetElement: '_Merkmale',    targetQualifier: 'Merkmale',
      label: 'Inspection Characteristics', position: 20 },
    { id: 'Protokoll',  type: #LINEITEM_REFERENCE,
      targetElement: '_ProtEintrag', targetQualifier: 'Protokoll',
      label: 'Upload Log',           position: 30 },
    { id: 'Vormerkliste', type: #LINEITEM_REFERENCE,
      targetElement: '_DlToken',     targetQualifier: 'Token',
      label: 'Watchlist',            position: 40 }
  ]
  @UI: { lineItem:       [{ position: 10, label: 'Inspection Lot' },
                          { type: #FOR_ACTION, dataAction: 'vormerken',
                            label: 'Add to Watchlist', position: 185 },
                          { type: #FOR_ACTION, dataAction: 'vormerken_loeschen',
                            label: 'Remove from Watchlist', position: 186 },
                          { type: #FOR_ACTION, dataAction: 'vormerkliste_leeren',
                            label: 'VML delete', position: 187,
                            invocationGrouping: #CHANGE_SET },
                          { type: #FOR_ACTION, dataAction: 'zuruecksetzen',
                            label: 'Reset', position: 190 }],
         identification: [{ position: 10 },
                          { type: #FOR_ACTION, dataAction: 'vormerken',
                            label: 'Add to Watchlist', position: 15 },
                          { type: #FOR_ACTION, dataAction: 'vormerken_loeschen',
                            label: 'Remove from Watchlist', position: 16 },
                          { type: #FOR_ACTION, dataAction: 'zuruecksetzen',
                            label: 'Reset', position: 25 }],
         selectionField: [{ position: 10 }],
         fieldGroup:     [{ qualifier: 'General', position: 10 }] }
  @Search.defaultSearchElement: true
  @Consumption.valueHelpDefinition: [ { entity: { name: 'I_InspectionLotVH', element: 'InspectionLot' } } ]
  key InspectionLot,

  @UI: { lineItem: [{ position: 11, label: 'Status',
                      criticality: 'StatusCriticality',
                      criticalityRepresentation: #WITH_ICON }] }
  @UI.selectionField: [{ position: 15 }]
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZJMQMI_I_STATUS_VH',
                                                  element: 'StatusText' } }]
  StatusText,

  @UI.hidden: true
  StatusCriticality,

  @UI.lineItem: [{ position: 12, label: 'Vorgemerkt',
                   criticality: 'IsVorgemerktCrit',
                   criticalityRepresentation: #WITH_ICON }]
  IsVorgemerkt,

  @UI.hidden: true
  IsVorgemerktCrit,

  @UI: { lineItem:       [{ position: 20, label: 'Plant' }],
         selectionField: [{ position: 20 }],
         fieldGroup:     [{ qualifier: 'General', position: 20 }] }
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Plant', element: 'Plant' } }]
  Plant,

  @UI: { lineItem:       [{ position: 30, label: 'Material' }],
         selectionField: [{ position: 30 }],
         fieldGroup:     [{ qualifier: 'General', position: 30 }] }
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialVH', element: 'Material' } }]
  @Search.defaultSearchElement: true
  Material,

  @UI: { fieldGroup: [{ qualifier: 'General', position: 40 }] }
  @Search.defaultSearchElement: true
  Batch,

  @UI: { fieldGroup: [{ qualifier: 'Quantities', position: 10 }] }
  InspectionLotQuantity,

  @UI: { fieldGroup: [{ qualifier: 'Quantities', position: 20 }] }
  InspectionLotQuantityUnit,

  @UI: { lineItem:       [{ position: 60, label: 'Created On' }],
         selectionField: [{ position: 17 }],
         fieldGroup:     [{ qualifier: 'General', position: 50 }] }
  @Consumption.filter.selectionType: #INTERVAL
  InspLotCreatedOnLocalDate,

  @UI: { selectionField: [{ position: 70 }],
         fieldGroup:     [{ qualifier: 'General', position: 60 }] }
  @OData.property.name: 'InspLotType'
  InspectionLotType,

  @UI.hidden: true
  DownloadUrl,

  @UI: { lineItem:    [{ position: 72, label: 'Download', type: #WITH_URL,
                         url: 'DownloadUrl', iconUrl: 'sap-icon://download' }],
         fieldGroup: [{ qualifier: 'DlUlStatus', position: 5, label: 'Download',
                        type: #WITH_URL, url: 'DownloadUrl', iconUrl: 'sap-icon://download' }] }
  DownloadText,

  @UI.hidden: true
  UploadUrl,

  @UI: { lineItem:    [{ position: 73, label: 'Upload', type: #WITH_URL,
                         url: 'UploadUrl', iconUrl: 'sap-icon://upload' }],
         fieldGroup: [{ qualifier: 'DlUlStatus', position: 6, label: 'Upload',
                        type: #WITH_URL, url: 'UploadUrl', iconUrl: 'sap-icon://upload' }] }
  UploadText,

  @UI.lineItem: [{ position: 74, label: 'DL Vormerkliste', type: #WITH_URL,
                   url: 'BatchDownloadUrl', iconUrl: 'sap-icon://download-from-cloud' }]
  BatchDownloadText,

  @UI.lineItem: [{ position: 75, label: 'UL Vormerkliste', type: #WITH_URL,
                   url: 'BatchUploadUrl', iconUrl: 'sap-icon://upload-to-cloud' }]
  BatchUploadText,

  @UI: { lineItem:   [{ position: 80, label: 'Description' }],
         fieldGroup: [{ qualifier: 'General', position: 70 }] }
  @Search.defaultSearchElement: true
  InspectionLotText,

  @UI: { lineItem:       [{ position: 90, label: 'Production Order' }],
         selectionField: [{ position: 90 }],
         fieldGroup:     [{ qualifier: 'General', position: 80 }] }
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductionOrderStdVH',
                                                  element: 'ProductionOrder' } }]
  ManufacturingOrder,

  @UI: { lineItem:       [{ position: 100, label: 'Purchase Order' }],
         selectionField: [{ position: 100 }],
         fieldGroup:     [{ qualifier: 'General', position: 90 }] }
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PurchaseOrderStdVH',
                                                  element: 'PurchaseOrder' } }]
  PurchasingDocument,

  @UI: { lineItem:   [{ position: 110, label: 'Usage Decision' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 30 }] }
  InspectionLotHasUsageDecision,

  @UI: { lineItem:   [{ position: 120, label: 'Auto UD' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 40 }] }
  InspLotIsAutomUsgeDcsnPossible,

  @UI: { lineItem:   [{ position: 130, label: 'Stock Posted' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 50 }] }
  InspLotIsStockPostingCompleted,

  @UI: { lineItem:   [{ position: 140, label: 'Inventory Mgmt' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 60 }] }
  InspectionLotHasQuantity,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 10, label: 'Last Download' }]
  LastDownloadAt,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 20, label: 'Downloaded By' }]
  LastDownloadBy,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 30, label: 'Last Upload' }]
  LastUploadAt,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 40, label: 'Uploaded By' }]
  LastUploadBy,

  @UI.hidden: true
  BatchDownloadUrl,

  @UI.hidden: true
  BatchUploadUrl,

  _ProtEintrag : redirected to composition child ZJMQMI_C_INSPLOT_PROT,
  _Merkmale    : redirected to composition child ZJMQMI_C_INSPLOT_CHAR,
  _DlToken     : redirected to composition child ZJMQMI_C_INSPLOT_TOKEN
}
