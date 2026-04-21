@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vormerkliste Flag pro Prueflos'
define view entity ZJMQMI_I_INSPLOT_TOKEN_FLAG
  as select from zjmqmit_dl_token
{
  key prueflos
}
group by prueflos
