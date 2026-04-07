@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Prueflose'
@Search.searchable: false
@Metadata.allowExtensions: true

@UI.headerInfo: {
  typeName:       'Prüflos',
  typeNamePlural: 'Prüflose',
  title:          { type: #STANDARD, value: 'InspectionLot' },
  description:    { type: #STANDARD, value: 'InspectionLotText' }
}

define root view entity ZJMQMI_C_INSPLOT
  provider contract transactional_query
  as projection on ZJMQMI_I_INSPLOT
{
  @UI.facet: [
    { id: 'Header',     type: #COLLECTION,          label: 'Allgemein',      position: 10 },
    { id: 'General',    type: #FIELDGROUP_REFERENCE, targetQualifier: 'General',
      parentId: 'Header', label: 'Stammdaten',        position: 10 },
    { id: 'DlUlStatus', type: #FIELDGROUP_REFERENCE, targetQualifier: 'DlUlStatus',
      parentId: 'Header', label: 'Download/Upload',   position: 20 },
    { id: 'Merkmale',   type: #LINEITEM_REFERENCE,
      targetElement: '_Merkmale',    targetQualifier: 'Merkmale',
      label: 'Pruefmerkmale',        position: 20 },
    { id: 'Protokoll',  type: #LINEITEM_REFERENCE,
      targetElement: '_ProtEintrag', targetQualifier: 'Protokoll',
      label: 'Upload-Protokoll',     position: 30 },
    { id: 'Vormerkliste', type: #LINEITEM_REFERENCE,
      targetElement: '_DlToken',     targetQualifier: 'Token',
      label: 'Vormerkliste',         position: 40 }
  ]
  @UI: { lineItem:       [{ position: 10, label: 'Prueflosnummer' },
                          { type: #FOR_ACTION, dataAction: 'vormerken',
                            label: 'Vormerken', position: 185 },
                          { type: #FOR_ACTION, dataAction: 'vormerken_loeschen',
                            label: 'Aus Vormerkliste löschen', position: 186 }],
         identification: [{ position: 10 },
                          { type: #FOR_ACTION, dataAction: 'vormerken',
                            label: 'Vormerkliste aufnehmen', position: 15 },
                          { type: #FOR_ACTION, dataAction: 'vormerkliste_leeren',
                            label: 'Vormerkliste leeren', position: 20 }],
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

  @UI: { lineItem:       [{ position: 20, label: 'Werk' }],
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

  @UI: { lineItem:       [{ position: 40, label: 'Charge' }],
         fieldGroup:     [{ qualifier: 'General', position: 40 }] }
  @Search.defaultSearchElement: true
  Batch,

  @UI: { lineItem:   [{ position: 50, label: 'Losmenge' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 10 }] }
  InspectionLotQuantity,

  @UI: { lineItem:   [{ position: 55, label: 'ME' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 20 }] }
  InspectionLotQuantityUnit,

  @UI: { lineItem:       [{ position: 60, label: 'Erstelldatum' }],
         selectionField: [{ position: 60 }],
         fieldGroup:     [{ qualifier: 'General', position: 50 }] }
  @Consumption.filter.selectionType: #INTERVAL
  InspLotCreatedOnLocalDate,

  @UI: { lineItem:       [{ position: 70, label: 'Pruefart' }],
         selectionField: [{ position: 70 }],
         fieldGroup:     [{ qualifier: 'General', position: 60 }] }
  @OData.property.name: 'InspLotType'
  InspectionLotType,

  @UI.lineItem: [{ position: 72, label: 'Einzel-XLSX', type: #WITH_URL,
                   url: 'DownloadUrl', iconUrl: 'sap-icon://download' }]
  DownloadUrl,

  @UI.lineItem: [{ position: 74, label: 'Vormerkliste laden', type: #WITH_URL,
                   url: 'BatchDownloadUrl', iconUrl: 'sap-icon://download-from-cloud' }]
  BatchDownloadText,

  @UI: { lineItem:   [{ position: 80, label: 'Kurztext' }],
         fieldGroup: [{ qualifier: 'General', position: 70 }] }
  @Search.defaultSearchElement: true
  InspectionLotText,

  @UI: { lineItem:       [{ position: 90, label: 'Fertigungsauftrag' }],
         selectionField: [{ position: 90 }],
         fieldGroup:     [{ qualifier: 'General', position: 80 }] }
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductionOrderStdVH',
                                                  element: 'ProductionOrder' } }]
  ManufacturingOrder,

  @UI: { lineItem:       [{ position: 100, label: 'Bestellung' }],
         selectionField: [{ position: 100 }],
         fieldGroup:     [{ qualifier: 'General', position: 90 }] }
  @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PurchaseOrderStdVH',
                                                  element: 'PurchaseOrder' } }]
  PurchasingDocument,

  @UI: { lineItem:   [{ position: 110, label: 'VE vorhanden' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 30 }] }
  InspectionLotHasUsageDecision,

  @UI: { lineItem:   [{ position: 120, label: 'autom. VE' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 40 }] }
  InspLotIsAutomUsgeDcsnPossible,

  @UI: { lineItem:   [{ position: 130, label: 'Bestand gebucht' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 50 }] }
  InspLotIsStockPostingCompleted,

  @UI: { lineItem:   [{ position: 140, label: 'Lagerwirtschaft' }],
         fieldGroup: [{ qualifier: 'Quantities', position: 60 }] }
  InspectionLotHasQuantity,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 10, label: 'Letzter Download' }]
  LastDownloadAt,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 20, label: 'Heruntergeladen von' }]
  LastDownloadBy,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 30, label: 'Letzter Upload' }]
  LastUploadAt,

  @UI.fieldGroup: [{ qualifier: 'DlUlStatus', position: 40, label: 'Hochgeladen von' }]
  LastUploadBy,

  @UI.hidden: true
  BatchDownloadUrl,

  _ProtEintrag : redirected to composition child ZJMQMI_C_INSPLOT_PROT,
  _Merkmale    : redirected to composition child ZJMQMI_C_INSPLOT_CHAR,
  _DlToken     : redirected to composition child ZJMQMI_C_INSPLOT_TOKEN
}
