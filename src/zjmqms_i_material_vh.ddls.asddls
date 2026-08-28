@EndUserText.label: 'Wertehilfe und Text Material'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity ZJMQMS_I_MATERIAL_VH
  as select from mara
    left outer join makt on  makt.matnr = mara.matnr
                         and makt.spras = $session.system_language
{
      @EndUserText.label: 'Material'
      @Search.defaultSearchElement: true
  key mara.matnr as Material,

      @EndUserText.label: 'Materialart'
      mara.mtart as MaterialType,

      @EndUserText.label: 'Basismengeneinheit'
      mara.meins as BaseUnit,

      @EndUserText.label: 'Materialkurztext'
      @Search.defaultSearchElement: true
      makt.maktx as MaterialName
}
