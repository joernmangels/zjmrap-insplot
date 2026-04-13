@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Pruefmerkmale'
define view entity ZJMQMI_C_INSPLOT_CHAR
  as projection on ZJMQMI_I_INSPLOT_CHAR
{
  @UI.facet: [
    { id: 'Spezifikation', type: #FIELDGROUP_REFERENCE, targetQualifier: 'Spezifikation',
      label: 'Spezifikation', position: 10 },
    { id: 'Ergebnis',      type: #FIELDGROUP_REFERENCE, targetQualifier: 'Ergebnis',
      label: 'Pruefergebnis', position: 20 }
  ]
  key InspectionLot,

  @UI.hidden: true
  key InspPlanOperationInternalID,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 20, label: 'Merkmal' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 20, label: 'Merkmal' }]
  key InspectionCharacteristic,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 10, label: 'Vorgang' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 10, label: 'Vorgang' }]
  InspectionOperation,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 15, label: 'Vorgangs-Beschreibung' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 15, label: 'Vorgangs-Beschreibung' }]
  OperationText,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 25, label: 'Stammmerkmal' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 25, label: 'Stammmerkmal' }]
  InspectionSpecification,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 28, label: 'QN/QL' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 28, label: 'QN/QL' }]
  QuanQual,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 30, label: 'Kurztext' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 30, label: 'Kurztext' }]
  InspectionCharacteristicText,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 35, label: 'FHM' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 35, label: 'FHM' }]
  InspectionMethod,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 37, label: 'FHM-Beschreibung' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 37, label: 'FHM-Beschreibung' }]
  InspectionMethodText,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 40, label: 'Sollwert QN' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 40, label: 'Sollwert QN' }]
  InspSpecTargetValue,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 50, label: 'Obergrenze QN' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 50, label: 'Obergrenze QN' }]
  InspSpecUpperLimit,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 60, label: 'Untergrenze QN' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 60, label: 'Untergrenze QN' }]
  InspSpecLowerLimit,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 63, label: 'Sollwert QL' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 63, label: 'Sollwert QL' }]
  SelectedCodeSet,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 66, label: 'Katalog QL' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 66, label: 'Katalog QL' }]
  CharacteristicAttributeCatalog,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 68, label: 'Losgröße' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 68, label: 'Losgröße' }]
  InspCharacteristicSampleSize,

  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 70, label: 'Einheit' }]
  InspectionSpecificationUnit,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 80, label: 'Messwert' }]
  @UI.fieldGroup:[{ qualifier: 'Ergebnis', position: 10, label: 'Messwert' }]
  InspectionResultMeanValue,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 90, label: 'Bewertung',
                    criticality: 'InspectionResultStatus',
                    criticalityRepresentation: #WITH_ICON }]
  @UI.fieldGroup:[{ qualifier: 'Ergebnis', position: 20, label: 'Bewertung',
                    criticality: 'InspectionResultStatus',
                    criticalityRepresentation: #WITH_ICON }]
  InspectionValuationResult,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 100, label: 'Merkmalstatus' }]
  @UI.fieldGroup:[{ qualifier: 'Ergebnis', position: 30, label: 'Merkmalstatus' }]
  InspectionCharacteristicStatus,

  @UI.hidden: true
  InspectionResultStatus,

  @UI.hidden: true
  InspectionMethodVersion,

  @UI.hidden: true
  InspectionMethodPlant,

  @UI.hidden: true
  InspSpecIsQuantitative,

  _InspectionLot : redirected to parent ZJMQMI_C_INSPLOT
}
