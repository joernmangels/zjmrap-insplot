@EndUserText.label: 'Wertehilfe Material (Strukturaufbau)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity /ENERCON/QM009_I_MAT_VH
  as select from mara
    left outer join makt on  makt.matnr = mara.matnr
                         and makt.spras = $session.system_language
{
      @EndUserText.label: 'Material'
      @Search.defaultSearchElement: true
  key mara.matnr as Material,

      @EndUserText.label: 'Materialkurztext'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      makt.maktx as MaterialName
}
