@EndUserText.label: 'Aktionsparameter Ersteinlesung'
define abstract entity ZJMQMS_A_ERSTEINLESUNG
{
      @EndUserText.label: 'Plantyp'
      PlanType     : plnty;

      @EndUserText.label: 'Plangruppe'
      PlanGroup    : plnnr;

      @EndUserText.label: 'Gruppenzaehler'
      GroupCounter : plnal;

      @EndUserText.label: 'Zaehler'
      NodeCounter  : cim_count;
}
