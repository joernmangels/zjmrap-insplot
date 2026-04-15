@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help: Prüflos-Status'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZJMQMI_I_STATUS_VH
  as select from dd07t
{
  key ddtext                                      as StatusText,
      case domvalue_l
        when 'N' then cast( 0 as abap.int2 )
        when 'D' then cast( 2 as abap.int2 )
        when 'S' then cast( 3 as abap.int2 )
        when 'E' then cast( 1 as abap.int2 )
        else          cast( 0 as abap.int2 )
      end                                         as StatusCriticality
}
where  domname    = 'ZJMQMI_D_STATUS'
  and  ddlanguage = $session.system_language
