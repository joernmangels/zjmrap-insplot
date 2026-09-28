@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Prueflose fuer Strukturaufbau'
@Search.searchable: true
define root view entity ZJMQMS_I_LOT
  as select from qals
  association [0..1] to makt as _MaterialText
    on  _MaterialText.matnr = $projection.Material
    and _MaterialText.spras = $session.system_language
{
      @Search.defaultSearchElement: true
  key qals.prueflos         as Prueflos,
      qals.werk             as Werk,
      qals.art              as Pruefart,
      qals.herkunft         as Herkunft,
      @ObjectModel.text.element: [ 'MaterialText' ]
      @Search.defaultSearchElement: true
      qals.matnr            as Material,
      @Semantics.text: true
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      _MaterialText.maktx   as MaterialText,
      qals.charg            as Charge,
      qals.enstehdat        as Entstehungsdatum,
      @Semantics.quantity.unitOfMeasure: 'Mengeneinheit'
      qals.losmenge         as Losmenge,
      qals.mengeneinh       as Mengeneinheit,

      _MaterialText
}
