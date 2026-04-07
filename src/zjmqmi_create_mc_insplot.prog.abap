REPORT zjmqmi_create_mc_insplot.

*DATA: lv_source   TYPE string,
*      lv_obj_name TYPE seu_objkey,
*      lt_messages TYPE STANDARD TABLE OF sym,
*      lv_package  TYPE devclass,
*      lv_tr       TYPE trkorr.
*
*lv_package  = 'ZJMRAP_INSPLOT'.
*lv_tr       = 'VIDK901389'.
*lv_obj_name = 'ZJMQMI_MC_INSPLOT'.
*
*lv_source =
*  '@Metadata.layer: #CUSTOMER' && cl_abap_char_utilities=>newline &&
*  'annotate view ZJMQMI_C_INSPLOT with' && cl_abap_char_utilities=>newline &&
*  '{' && cl_abap_char_utilities=>newline &&
*  '  @UI.headerInfo: {' && cl_abap_char_utilities=>newline &&
*  '    typeName: ''Prueflos'',' && cl_abap_char_utilities=>newline &&
*  '    typeNamePlural: ''Prueflose'',' && cl_abap_char_utilities=>newline &&
*  '    title: { type: #STANDARD, value: ''InspectionLot'' },' && cl_abap_char_utilities=>newline &&
*  '    description: { type: #STANDARD, value: ''InspectionLotText'' }' && cl_abap_char_utilities=>newline &&
*  '  }' && cl_abap_char_utilities=>newline &&
*  '  @UI.facet: [' && cl_abap_char_utilities=>newline &&
*  '    { id: ''Header'', type: #COLLECTION, label: ''Allgemein'', position: 10 },' && cl_abap_char_utilities=>newline &&
*  '    { id: ''General'', type: #FIELDGROUP_REFERENCE, targetQualifier: ''General'', parentId: ''Header'', label: ''Stammdaten'', position: 10 },' && cl_abap_char_utilities=>newline &&
*  '    { id: ''Quantities'', type: #FIELDGROUP_REFERENCE, targetQualifier: ''Quantities'', parentId: ''Header'', label: ''Mengen und Status'', position: 20 },' && cl_abap_char_utilities=>newline &&
*  '    { id: ''DlUlStatus'', type: #FIELDGROUP_REFERENCE, targetQualifier: ''DlUlStatus'', parentId: ''Header'', label: ''Download/Upload'', position: 30 },' && cl_abap_char_utilities=>newline &&
*  '    { id: ''Protokoll'', type: #LINEITEM_REFERENCE, targetElement: ''_ProtEintrag'', targetQualifier: ''Protokoll'', label: ''Upload-Protokoll'', position: 20 }' && cl_abap_char_utilities=>newline &&
*  '  ]' && cl_abap_char_utilities=>newline &&
*  '  InspectionLot;' && cl_abap_char_utilities=>newline &&
*  '}'.
*
*DATA: lo_ddls TYPE REF TO cl_dd_ddl_handler.
*DATA: lv_ddlx_name TYPE c LENGTH 30 VALUE 'ZJMQMI_MC_INSPLOT'.
*
*" Use CL_DD_DDL_HANDLER to create DDLX
*TRY.
*    lo_ddls = cl_dd_ddl_handler=>create_instance(
*                iv_object_name  = lv_ddlx_name
*                iv_object_type  = 'DDLX'
*                iv_package      = lv_package
*                iv_request      = lv_tr ).
*    lo_ddls->set_source( iv_source = lv_source ).
*    lo_ddls->activate( ).
*    WRITE: / 'Success: ZJMQMI_MC_INSPLOT activated'.
*  CATCH cx_root INTO DATA(lx).
*    WRITE: / 'Error:', lx->get_text( ).
*ENDTRY.
