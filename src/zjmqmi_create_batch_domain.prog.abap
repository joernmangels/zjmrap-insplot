REPORT zjmqmi_create_batch_domain.

" Einmalig ausführen in SA38, danach Domain ZJMQMI_D_BATCH_ACTION in SE11 aktivieren (Strg+F3)

DATA: ls_dd01v  TYPE dd01v,
      lt_dd07v  TYPE TABLE OF dd07v,
      lv_rc     TYPE sy-subrc.

ls_dd01v-domname   = 'ZJMQMI_D_BATCH_ACTION'.
ls_dd01v-ddlanguage = sy-langu.
ls_dd01v-datatype  = 'CHAR'.
ls_dd01v-leng      = 1.
ls_dd01v-outputlen = 1.
ls_dd01v-ddtext    = 'Batch-Aktion (Download/Upload)'.

APPEND VALUE dd07v(
  domname    = 'ZJMQMI_D_BATCH_ACTION'
  valpos     = '0001'
  domvalue_l = 'D'
  ddlanguage = sy-langu
  ddtext     = 'Vormerkliste laden'
) TO lt_dd07v.

APPEND VALUE dd07v(
  domname    = 'ZJMQMI_D_BATCH_ACTION'
  valpos     = '0002'
  domvalue_l = 'U'
  ddlanguage = sy-langu
  ddtext     = 'Vormerkliste hochladen'
) TO lt_dd07v.

CALL FUNCTION 'DDIF_DOMA_PUT'
  EXPORTING
    name              = 'ZJMQMI_D_BATCH_ACTION'
    dd01v_wa          = ls_dd01v
  TABLES
    dd07v_tab         = lt_dd07v
  EXCEPTIONS
    doma_not_found    = 1
    name_inconsistent = 2
    doma_inconsistent = 3
    put_failure       = 4
    put_refused       = 5
    OTHERS            = 6.

IF sy-subrc = 0.
  MESSAGE 'Domain ZJMQMI_D_BATCH_ACTION angelegt. Bitte in SE11 aktivieren (Strg+F3).' TYPE 'S'.
ELSE.
  MESSAGE |Fehler beim Anlegen: sy-subrc={ sy-subrc }| TYPE 'E'.
ENDIF.
