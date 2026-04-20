@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Prüflos Upload-Protokoll Interface View'
define view entity ZJMQMI_I_INSPLOT_PROT
  as select from zjmqmit_prot
  association to parent ZJMQMI_I_INSPLOT as _InspectionLot
    on $projection.InspectionLot = _InspectionLot.InspectionLot
{
  key prueflos       as InspectionLot,
  key prot_guid      as ProtGuid,
      prot_timestamp as ProtTimestamp,
      prot_filename  as FileName,
      prot_rownr     as RowNumber,
      cast( prot_inspoper as abap.char( 4 ) )   as InspectionOperation,
      cast( prot_insp_char as abap.char( 4 ) )  as InspectionCharacteristic,
      prot_radii_code                            as RadiiCode,
      prot_radii_codegrp                         as RadiiCodeGroup,
      prot_radii_kurztext                        as RadiiKurztext,
      prot_status    as Status,
      prot_msg       as Message,
      created_by     as CreatedBy,
      created_at     as CreatedAt,
      _InspectionLot
}
