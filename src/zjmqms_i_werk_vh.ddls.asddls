@EndUserText.label: 'Wertehilfe Werk'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity ZJMQMS_I_WERK_VH
  as select from t001w
{
      @EndUserText.label: 'Werk'
      @Search.defaultSearchElement: true
  key werks as Werk,

      @EndUserText.label: 'Name'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      name1 as WerkName
}
