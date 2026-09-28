@EndUserText.label: 'Wertehilfe Pruefart'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity /ENERCON/QM009_I_PRUEFART_VH
  as select from tq30
    left outer join tq30t on  tq30t.art     = tq30.art
                          and tq30t.sprache = $session.system_language
{
      @EndUserText.label: 'Pruefart'
      @Search.defaultSearchElement: true
  key tq30.art       as Pruefart,

      @EndUserText.label: 'Bezeichnung'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      tq30t.kurztext as PruefartText
}
