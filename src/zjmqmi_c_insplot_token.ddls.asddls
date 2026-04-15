@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View Download Token'

@UI.headerInfo: {
  typeName:       'Watchlist Entry',
  typeNamePlural: 'Watchlist',
  title:       { type: #STANDARD, value: 'CreatedBy' },
  description: { type: #STANDARD, value: 'CreatedAt' }
}

define view entity ZJMQMI_C_INSPLOT_TOKEN
  as projection on ZJMQMI_I_INSPLOT_TOKEN
{
  @UI.facet: [
    { id: 'General', type: #FIELDGROUP_REFERENCE, targetQualifier: 'General',
      label: 'Watchlist Entry', position: 10 }
  ]

  @UI.hidden: true
  key InspectionLot,

  @UI.fieldGroup:    [{ qualifier: 'General', position: 10, label: 'Added By' }]
  @UI.identification:[{ position: 10, label: 'Added By' }]
  @UI.lineItem:      [{ qualifier: 'Token',   position: 10, label: 'Added By' }]
  key CreatedBy,

  @UI.fieldGroup:    [{ qualifier: 'General', position: 20, label: 'Added On' }]
  @UI.identification:[{ position: 20, label: 'Added On' }]
  @UI.lineItem:      [{ qualifier: 'Token',   position: 20, label: 'Added On' }]
  CreatedAt,

  _InspectionLot: redirected to parent ZJMQMI_C_INSPLOT
}
