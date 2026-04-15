REPORT zjmqmi_create_domain.

DATA: ls_dd01v  TYPE dd01v,
      lt_dd07v  TYPE TABLE OF dd07v,
      ls_dd07v  TYPE dd07v.

" --- Domain-Kopf ---
ls_dd01v-domname    = 'ZJMQMI_D_STATUS'.
ls_dd01v-ddlanguage = sy-langu.
ls_dd01v-datatype   = 'CHAR'.
ls_dd01v-leng       = 1.
ls_dd01v-outputlen  = 1.
ls_dd01v-ddtext     = 'QM Prüflos Upload-Status'.

" --- Festwerte ---
ls_dd07v-domname    = 'ZJMQMI_D_STATUS'.
ls_dd07v-ddlanguage = sy-langu.

ls_dd07v-valpos     = '0001'.
ls_dd07v-domvalue_l = 'N'.
ls_dd07v-ddtext     = 'Kein Status'.
APPEND ls_dd07v TO lt_dd07v.

ls_dd07v-valpos     = '0002'.
ls_dd07v-domvalue_l = 'D'.
ls_dd07v-ddtext     = 'Heruntergeladen'.
APPEND ls_dd07v TO lt_dd07v.

ls_dd07v-valpos     = '0003'.
ls_dd07v-domvalue_l = 'S'.
ls_dd07v-ddtext     = 'Hochgeladen (fehlerfrei)'.
APPEND ls_dd07v TO lt_dd07v.

ls_dd07v-valpos     = '0004'.
ls_dd07v-domvalue_l = 'E'.
ls_dd07v-ddtext     = 'Hochgeladen (mit Fehlern)'.
APPEND ls_dd07v TO lt_dd07v.

" --- Speichern (inaktiv) ---
CALL FUNCTION 'DDIF_DOMA_PUT'
  EXPORTING
    name              = 'ZJMQMI_D_STATUS'
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
  WRITE: / 'Domain ZJMQMI_D_STATUS gespeichert (inaktiv).'.
  WRITE: / 'Bitte in SE11 öffnen und aktivieren (Strg+F3).'.
ELSE.
  WRITE: / 'DDIF_DOMA_PUT Fehler, SY-SUBRC:', sy-subrc.
ENDIF.
