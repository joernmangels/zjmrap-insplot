@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View Prüflose'
@Metadata.allowExtensions: true
define root view entity ZJMQMI_I_INSPLOT
  as select from I_InspectionLot as il
  left outer join zjmqmit_status as _Stat
    on _Stat.prueflos = il.InspectionLot
  left outer join ZJMQMI_I_STATUS_CODE as _Sc
    on _Sc.prueflos = il.InspectionLot
  left outer join dd07t as _StatusDD
    on  _StatusDD.domname    = 'ZJMQMI_D_STATUS'
    and _StatusDD.domvalue_l = _Sc.StatusCode
    and _StatusDD.ddlanguage = $session.system_language
  left outer join ZJMQMI_I_INSPLOT_TOKEN_FLAG as _Flag
    on _Flag.prueflos = il.InspectionLot
  composition [0..*] of ZJMQMI_I_INSPLOT_PROT  as _ProtEintrag
  composition [0..*] of ZJMQMI_I_INSPLOT_CHAR  as _Merkmale
  composition [0..*] of ZJMQMI_I_INSPLOT_TOKEN as _DlToken
{
  key il.InspectionLot,
      il.Plant,
      il.Material,
      il.Batch,
      il.InspectionLotQuantity,
      il.InspectionLotQuantityUnit,
      il.InspLotCreatedOnLocalDate,
      il.InspectionLotType,
      il.InspectionLotText,
      il.ManufacturingOrder,
      il.PurchasingDocument,
      il.InspectionLotHasUsageDecision,
      il.InspLotIsAutomUsgeDcsnPossible,
      il.InspLotIsStockPostingCompleted,
      il.InspectionLotHasQuantity,

      @EndUserText.label: 'Status'
      cast( _StatusDD.ddtext as abap.char( 25 ) ) as StatusText,

      case when _Stat.last_ul_status = 'E'  then cast( 1 as abap.int2 )
           when _Stat.last_ul_status = 'S'  then cast( 3 as abap.int2 )
           when _Stat.last_dl_at is not null then cast( 2 as abap.int2 )
           else                                    cast( 0 as abap.int2 )
      end                           as StatusCriticality,

      _Stat.last_dl_at              as LastDownloadAt,
      _Stat.last_dl_by              as LastDownloadBy,
      _Stat.last_ul_at              as LastUploadAt,
      _Stat.last_ul_by              as LastUploadBy,

      concat( '/sap/bc/zjmqmi/download?lot=',
              il.InspectionLot )    as DownloadUrl,

      cast( 'Download PL' as abap.char(20) ) as DownloadText,

      concat( '/sap/bc/zjmqmi/upload?lot=',
              il.InspectionLot )    as UploadUrl,

      cast( 'Upload PL' as abap.char(20) )   as UploadText,

      case when _Flag.prueflos is not null
           then cast( 3 as abap.int1 )
           else cast( 0 as abap.int1 )
      end                                                as IsVorgemerktCrit,

      cast( '' as abap.char(1) )                         as IsVorgemerkt,

      cast( '/sap/bc/zjmqmi/download' as abap.char(200) ) as BatchDownloadUrl,
      cast( 'DL Vormerkliste'         as abap.char(50) )  as BatchDownloadText,
      cast( '/sap/bc/zjmqmi/upload'  as abap.char(200) ) as BatchUploadUrl,
      cast( 'UL Vormerkliste'         as abap.char(50) )  as BatchUploadText,

      _ProtEintrag,
      _Merkmale,
      _DlToken
}
