@EndUserText.label: 'Equi-Struktur zum Pruefplan'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZJMQMS_I_EQUISTRUK
  as select from zjmqm_qm009_q
{
      @EndUserText.label: 'Plantyp'
  key plnty as PlanType,

      @EndUserText.label: 'Plangruppe'
  key plnnr as PlanGroup,

      @EndUserText.label: 'Gruppenzaehler'
  key plnal as GroupCounter,

      @EndUserText.label: 'Zaehler'
  key zaehl as NodeCounter,

      @EndUserText.label: 'Laufende Nummer'
  key lfdnr as SeqNumber,

      mat_ebene0  as MatEbene00,
      mat_ebene1  as MatEbene01,
      mat_ebene2  as MatEbene02,
      mat_ebene3  as MatEbene03,
      mat_ebene4  as MatEbene04,
      mat_ebene5  as MatEbene05,
      mat_ebene6  as MatEbene06,
      mat_ebene7  as MatEbene07,
      mat_ebene8  as MatEbene08,
      mat_ebene9  as MatEbene09,
      mat_ebene10 as MatEbene10,
      mat_ebene11 as MatEbene11,
      mat_ebene12 as MatEbene12,
      mat_ebene13 as MatEbene13,
      mat_ebene14 as MatEbene14,
      mat_ebene15 as MatEbene15,
      mat_ebene16 as MatEbene16,
      mat_ebene17 as MatEbene17,
      mat_ebene18 as MatEbene18,
      mat_ebene19 as MatEbene19,

      @EndUserText.label: 'Ebene'
      case when mat_ebene0  <> '' then cast( 0  as abap.int2 )
           when mat_ebene1  <> '' then cast( 1  as abap.int2 )
           when mat_ebene2  <> '' then cast( 2  as abap.int2 )
           when mat_ebene3  <> '' then cast( 3  as abap.int2 )
           when mat_ebene4  <> '' then cast( 4  as abap.int2 )
           when mat_ebene5  <> '' then cast( 5  as abap.int2 )
           when mat_ebene6  <> '' then cast( 6  as abap.int2 )
           when mat_ebene7  <> '' then cast( 7  as abap.int2 )
           when mat_ebene8  <> '' then cast( 8  as abap.int2 )
           when mat_ebene9  <> '' then cast( 9  as abap.int2 )
           when mat_ebene10 <> '' then cast( 10 as abap.int2 )
           when mat_ebene11 <> '' then cast( 11 as abap.int2 )
           when mat_ebene12 <> '' then cast( 12 as abap.int2 )
           when mat_ebene13 <> '' then cast( 13 as abap.int2 )
           when mat_ebene14 <> '' then cast( 14 as abap.int2 )
           when mat_ebene15 <> '' then cast( 15 as abap.int2 )
           when mat_ebene16 <> '' then cast( 16 as abap.int2 )
           when mat_ebene17 <> '' then cast( 17 as abap.int2 )
           when mat_ebene18 <> '' then cast( 18 as abap.int2 )
           when mat_ebene19 <> '' then cast( 19 as abap.int2 )
           else cast( 99 as abap.int2 )
      end   as Ebene,

      @EndUserText.label: 'Material'
      case when mat_ebene0  <> '' then cast( mat_ebene0  as matnr )
           when mat_ebene1  <> '' then cast( mat_ebene1  as matnr )
           when mat_ebene2  <> '' then cast( mat_ebene2  as matnr )
           when mat_ebene3  <> '' then cast( mat_ebene3  as matnr )
           when mat_ebene4  <> '' then cast( mat_ebene4  as matnr )
           when mat_ebene5  <> '' then cast( mat_ebene5  as matnr )
           when mat_ebene6  <> '' then cast( mat_ebene6  as matnr )
           when mat_ebene7  <> '' then cast( mat_ebene7  as matnr )
           when mat_ebene8  <> '' then cast( mat_ebene8  as matnr )
           when mat_ebene9  <> '' then cast( mat_ebene9  as matnr )
           when mat_ebene10 <> '' then cast( mat_ebene10 as matnr )
           when mat_ebene11 <> '' then cast( mat_ebene11 as matnr )
           when mat_ebene12 <> '' then cast( mat_ebene12 as matnr )
           when mat_ebene13 <> '' then cast( mat_ebene13 as matnr )
           when mat_ebene14 <> '' then cast( mat_ebene14 as matnr )
           when mat_ebene15 <> '' then cast( mat_ebene15 as matnr )
           when mat_ebene16 <> '' then cast( mat_ebene16 as matnr )
           when mat_ebene17 <> '' then cast( mat_ebene17 as matnr )
           when mat_ebene18 <> '' then cast( mat_ebene18 as matnr )
           when mat_ebene19 <> '' then cast( mat_ebene19 as matnr )
           else cast( '' as matnr )
      end   as Material
}
