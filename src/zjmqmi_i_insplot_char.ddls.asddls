@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View Pruefmerkmale'
define view entity ZJMQMI_I_INSPLOT_CHAR
  as select from I_InspectionCharacteristic
  left outer join I_InspectionResult as _Res
    on  _Res.InspectionLot              = I_InspectionCharacteristic.InspectionLot
    and _Res.InspPlanOperationInternalID = I_InspectionCharacteristic.InspPlanOperationInternalID
    and _Res.InspectionCharacteristic    = I_InspectionCharacteristic.InspectionCharacteristic
  left outer join I_InspectionOperation as _Oper
    on  _Oper.InspectionLot              = I_InspectionCharacteristic.InspectionLot
    and _Oper.InspPlanOperationInternalID = I_InspectionCharacteristic.InspPlanOperationInternalID
  left outer join I_InspectionMethodVersionText as _MethTxt
    on  _MethTxt.InspectionMethodPlant   = I_InspectionCharacteristic.InspectionMethodPlant
    and _MethTxt.InspectionMethod        = I_InspectionCharacteristic.InspectionMethod
    and _MethTxt.InspectionMethodVersion = I_InspectionCharacteristic.InspectionMethodVersion
    and _MethTxt.Language                = $session.system_language
  association to parent ZJMQMI_I_INSPLOT as _InspectionLot
    on $projection.InspectionLot = _InspectionLot.InspectionLot
{
  key I_InspectionCharacteristic.InspectionLot,
  key I_InspectionCharacteristic.InspPlanOperationInternalID,
  key I_InspectionCharacteristic.InspectionCharacteristic,
      cast( _Oper.InspectionOperation as abap.char(4) ) as InspectionOperation,
      _Oper.OperationText,
      I_InspectionCharacteristic.InspectionCharacteristicText,
      I_InspectionCharacteristic.InspectionCharacteristicStatus,
      I_InspectionCharacteristic.InspSpecTargetValue,
      I_InspectionCharacteristic.InspSpecUpperLimit,
      I_InspectionCharacteristic.InspSpecLowerLimit,
      I_InspectionCharacteristic.InspectionSpecificationUnit,
      _Res.InspectionValuationResult,
      _Res.InspectionResultMeanValue,
      _Res.InspectionResultStatus,
      I_InspectionCharacteristic.InspectionMethod,
      I_InspectionCharacteristic.InspectionMethodVersion,
      I_InspectionCharacteristic.InspectionMethodPlant,
      _MethTxt.InspectionMethodText,
      I_InspectionCharacteristic.InspectionSpecification,
      I_InspectionCharacteristic.SelectedCodeSet,
      I_InspectionCharacteristic.CharacteristicAttributeCatalog,
      I_InspectionCharacteristic.InspCharacteristicSampleSize,
      I_InspectionCharacteristic.InspSpecIsQuantitative,
      case I_InspectionCharacteristic.InspSpecIsQuantitative
        when 'X' then cast( 'QN' as abap.char(2) )
        else          cast( 'QL' as abap.char(2) )
      end as QuanQual,
      _InspectionLot
}
