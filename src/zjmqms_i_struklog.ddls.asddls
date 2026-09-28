@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Protokoll Equipment-Strukturaufbau'
define view entity ZJMQMS_I_STRUKLOG
  as select from zjmqms_struklog
  association [0..1] to ZJMQMS_I_LOT as _Lot
    on _Lot.Prueflos = $projection.Prueflos
{
  key run_id     as RunId,
  key seq        as Seq,
      prueflos   as Prueflos,
      testmode   as Testmodus,
      step       as Schritt,
      @EndUserText.label: 'Vorgang'
      cast( vornr as abap.char(4) ) as Vorgang,
//      vornr as abap.char(4) ) as Vorgang,
      matnr      as Material,
      @EndUserText.label: 'Serialnummer'
      cast( sernr as abap.char(18) ) as Serialnummer,
      equnr      as Equipment,
      action     as Aktion,
      status     as Status,
      msg        as Meldung,
      @Semantics.user.createdBy: true
      created_by as ErstelltVon,
      @Semantics.systemDateTime.createdAt: true
      created_at as ErstelltAm,

      _Lot
}
