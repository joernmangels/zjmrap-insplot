@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Download-Token'

@UI.headerInfo: {
  typeName:       'Vormerkeintrag',
  typeNamePlural: 'Vormerkliste',
  title:       { type: #STANDARD, value: 'CreatedBy' },
  description: { type: #STANDARD, value: 'CreatedAt' }
}

define view entity ZJMQMI_C_INSPLOT_TOKEN
  as projection on ZJMQMI_I_INSPLOT_TOKEN
{
  @UI.facet: [
    { id: 'General', type: #FIELDGROUP_REFERENCE, targetQualifier: 'General',
      label: 'Vormerkeintrag', position: 10 }
  ]

  @UI.hidden: true
  key InspectionLot,

  @UI.fieldGroup:    [{ qualifier: 'General', position: 10, label: 'Vorgemerkt von' }]
  @UI.identification:[{ position: 10, label: 'Vorgemerkt von' }]
  @UI.lineItem:      [{ qualifier: 'Token',   position: 10, label: 'Vorgemerkt von' }]
  key CreatedBy,

  @UI.fieldGroup:    [{ qualifier: 'General', position: 20, label: 'Vorgemerkt am' }]
  @UI.identification:[{ position: 20, label: 'Vorgemerkt am' }]
  @UI.lineItem:      [{ qualifier: 'Token',   position: 20, label: 'Vorgemerkt am' }]
  CreatedAt,

  _InspectionLot: redirected to parent ZJMQMI_C_INSPLOT
}
