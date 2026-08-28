@EndUserText.label: 'Equi-Struktur zum Pruefplan'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZJMQMS_C_EQUISTRUK
  provider contract transactional_query
  as projection on ZJMQMS_I_EQUISTRUK
  association [0..1] to ZJMQMS_I_MATERIAL_VH as _MatText
    on $projection.Material = _MatText.Material
{
  key PlanType,
  key PlanGroup,
  key GroupCounter,
  key NodeCounter,
  key SeqNumber,

      MatEbene00,
      MatEbene01,
      MatEbene02,
      MatEbene03,
      MatEbene04,
      MatEbene05,
      MatEbene06,
      MatEbene07,
      MatEbene08,
      MatEbene09,
      MatEbene10,
      MatEbene11,
      MatEbene12,
      MatEbene13,
      MatEbene14,
      MatEbene15,
      MatEbene16,
      MatEbene17,
      MatEbene18,
      MatEbene19,

      Ebene,
      Material,

      _MatText
}
