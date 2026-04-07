@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View Download-Token'
define view entity ZJMQMI_I_INSPLOT_TOKEN
  as select from zjmqmit_dl_token
  association to parent ZJMQMI_I_INSPLOT as _InspectionLot
    on $projection.InspectionLot = _InspectionLot.InspectionLot
{
  key prueflos   as InspectionLot,
  key created_by as CreatedBy,
      created_at as CreatedAt,
      _InspectionLot
}
