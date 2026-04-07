@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help: Prüflos-Status'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZJMQMI_I_STATUS_VH
  as select from T000
{
  key cast( 'Kein Status' as abap.char(30) ) as StatusText,
      cast( 0 as abap.int2 )      as StatusCriticality
}
where mandt = $session.client
union all
select from T000
{
  key 'Heruntergeladen'           as StatusText,
      cast( 2 as abap.int2 )      as StatusCriticality
}
where mandt = $session.client
union all
select from T000
{
  key 'Hochgeladen (fehlerfrei)'  as StatusText,
      cast( 3 as abap.int2 )      as StatusCriticality
}
where mandt = $session.client
union all
select from T000
{
  key 'Hochgeladen (mit Fehlern)' as StatusText,
      cast( 1 as abap.int2 )      as StatusCriticality
}
where mandt = $session.client
