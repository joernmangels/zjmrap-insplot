@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View Prüflose'
@Metadata.allowExtensions: true
define root view entity ZJMQMI_I_INSPLOT
  as select from I_InspectionLot as il
  left outer join zjmqmit_status as _Stat
    on _Stat.prueflos = il.InspectionLot
  left outer join zjmqmit_dl_token as _Tok
    on  _Tok.prueflos   = il.InspectionLot
    and _Tok.created_by = $session.user
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

      case when _Stat.last_ul_status = 'E'  then 'Hochgeladen (mit Fehlern)'
           when _Stat.last_ul_status = 'S'  then 'Hochgeladen (fehlerfrei)'
           when _Stat.last_dl_at is not null then 'Heruntergeladen'
           else                                   'Kein Status'
      end                           as StatusText,

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

      case when _Tok.prueflos is not null
           then cast( '/sap/bc/zjmqmi/download' as abap.char(200) )
           else cast( '' as abap.char(200) )
      end                           as BatchDownloadUrl,

      case when _Tok.prueflos is not null
           then cast( 'Vormerkliste laden' as abap.char(50) )
           else cast( '' as abap.char(50) )
      end                           as BatchDownloadText,

      _ProtEintrag,
      _Merkmale,
      _DlToken
}
