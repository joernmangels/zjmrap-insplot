@EndUserText.label: 'Ergebnis der Ersteinlesung'
define abstract entity ZJMQMS_A_EINLESEN_ERG
{
      @EndUserText.label: 'Geloeschte Zeilen'
      Deleted : abap.int4;

      @EndUserText.label: 'Angelegte Zeilen'
      Created : abap.int4;

      @EndUserText.label: 'Uebersprungene Vorgaenge'
      Skipped : abap.int4;
}
