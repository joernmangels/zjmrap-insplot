@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Hilfssicht: Statuscode je Prüflos'
define view entity ZJMQMI_I_STATUS_CODE
  as select from zjmqmit_status
{
  key prueflos,

      case when last_ul_status = 'E'  then cast( 'E' as abap.char(1) )
           when last_ul_status = 'S'  then cast( 'S' as abap.char(1) )
           when last_dl_at is not null then cast( 'D' as abap.char(1) )
           else                             cast( 'N' as abap.char(1) )
      end as StatusCode
}
