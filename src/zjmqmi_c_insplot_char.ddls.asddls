@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Insp. Characteristics'
define view entity ZJMQMI_C_INSPLOT_CHAR
  as projection on ZJMQMI_I_INSPLOT_CHAR
{
  @UI.facet: [
    { id: 'Spezifikation', type: #FIELDGROUP_REFERENCE, targetQualifier: 'Spezifikation',
      label: 'Specification', position: 10 },
    { id: 'Ergebnis',      type: #FIELDGROUP_REFERENCE, targetQualifier: 'Ergebnis',
      label: 'Inspection Result', position: 20 }
  ]
  key InspectionLot,

  @UI.hidden: true
  key InspPlanOperationInternalID,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 20, label: 'Characteristic' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 20, label: 'Characteristic' }]
  key InspectionCharacteristic,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 10, label: 'Operation' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 10, label: 'Operation' }]
  InspectionOperation,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 15, label: 'Operation Description' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 15, label: 'Operation Description' }]
  OperationText,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 25, label: 'Master Characteristic' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 25, label: 'Master Characteristic' }]
  InspectionSpecification,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 28, label: 'QN/QL' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 28, label: 'QN/QL' }]
  QuanQual,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 30, label: 'Short Text' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 30, label: 'Short Text' }]
  InspectionCharacteristicText,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 35, label: 'Sampling Proc.' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 35, label: 'Sampling Proc.' }]
  InspectionMethod,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 37, label: 'Sampling Proc. Descr.' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 37, label: 'Sampling Proc. Descr.' }]
  InspectionMethodText,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 40, label: 'Target Value QN' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 40, label: 'Target Value QN' }]
  InspSpecTargetValue,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 50, label: 'Upper Limit QN' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 50, label: 'Upper Limit QN' }]
  InspSpecUpperLimit,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 60, label: 'Lower Limit QN' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 60, label: 'Lower Limit QN' }]
  InspSpecLowerLimit,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 63, label: 'Target Value QL' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 63, label: 'Target Value QL' }]
  SelectedCodeSet,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 66, label: 'Catalog QL' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 66, label: 'Catalog QL' }]
  CharacteristicAttributeCatalog,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 68, label: 'Lot Size' }]
  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 68, label: 'Lot Size' }]
  InspCharacteristicSampleSize,

  @UI.fieldGroup:[{ qualifier: 'Spezifikation', position: 70, label: 'Unit' }]
  InspectionSpecificationUnit,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 80, label: 'Result Value' }]
  @UI.fieldGroup:[{ qualifier: 'Ergebnis', position: 10, label: 'Result Value' }]
  InspectionResultMeanValue,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 90, label: 'Valuation',
                    criticality: 'InspectionResultStatus',
                    criticalityRepresentation: #WITH_ICON }]
  @UI.fieldGroup:[{ qualifier: 'Ergebnis', position: 20, label: 'Valuation',
                    criticality: 'InspectionResultStatus',
                    criticalityRepresentation: #WITH_ICON }]
  InspectionValuationResult,

  @UI.lineItem:  [{ qualifier: 'Merkmale', position: 100, label: 'Char. Status' }]
  @UI.fieldGroup:[{ qualifier: 'Ergebnis', position: 30, label: 'Char. Status' }]
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
