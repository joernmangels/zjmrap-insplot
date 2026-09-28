FUNCTION /enercon/qm009_struk_run
  IMPORTING
    VALUE(iv_prueflos) TYPE qplos
    VALUE(iv_test) TYPE abap_boolean DEFAULT abap_true
  EXPORTING
    VALUE(ev_run_id) TYPE sysuuid_x16.
" Legt Serialnummern/Equipments zum Prueflos an, baut sie nach der
" Soll-Struktur ein und schreibt das Protokoll nach /ENERCON/QM009_L.
"
" Remotefaehig, weil die Klassen committen: Die RAP-Aktion ruft den
" Baustein per DESTINATION 'NONE' in einer eigenen LUW auf.
" Initiale ev_run_id: Lauf-ID nicht erzeugbar, nichts geschehen.

  DATA lt_log TYPE /enercon/qm009_cl_lot_equi=>tt_log.
  DATA lo_lot TYPE REF TO /enercon/qm009_cl_lot_equi.
  DATA lv_now TYPE timestampl.

  CLEAR ev_run_id.
  TRY.
      DATA(lv_run_id) = cl_system_uuid=>create_uuid_x16_static( ).
    CATCH cx_uuid_error.
      RETURN.
  ENDTRY.

  " Wie lcl_report->process_lot im Report /ENERCON/QM009_R_EQUI_STRUKTUR
  TRY.
      lo_lot = NEW #( iv_prueflos = iv_prueflos
                      iv_test     = iv_test ).
      DATA(lt_equi) = lo_lot->run( ).
      lt_log = lo_lot->get_log( ).

      " Ohne Equipments gibt es nichts einzubauen
      IF lt_equi IS NOT INITIAL.
        DATA(lo_struktur) = NEW /enercon/qm009_cl_equi_struk( is_qals = lo_lot->get_lot( )
                                                         it_equi = lt_equi
                                                         iv_test = iv_test ).
        APPEND LINES OF lo_struktur->run( ) TO lt_log.
      ENDIF.

    CATCH cx_root INTO DATA(lx_error).
      " Ein Abbruch soll im Protokoll stehen statt im Aufrufer zu enden
      IF lt_log IS INITIAL AND lo_lot IS BOUND.
        lt_log = lo_lot->get_log( ).
      ENDIF.
      APPEND VALUE #( prueflos = iv_prueflos
                      action   = 'abgebrochen'
                      status   = 'E'
                      msg      = lx_error->get_text( ) ) TO lt_log.
  ENDTRY.

  GET TIME STAMP FIELD lv_now.

  DATA lt_db TYPE STANDARD TABLE OF /enercon/qm009_l WITH EMPTY KEY.
  lt_db = VALUE #( FOR ls_log IN lt_log INDEX INTO lv_seq
                   ( run_id     = lv_run_id
                     seq        = lv_seq
                     prueflos   = iv_prueflos
                     testmode   = iv_test
                     step       = ls_log-step
                     vornr      = ls_log-vornr
                     matnr      = ls_log-matnr
                     sernr      = ls_log-sernr
                     equnr      = ls_log-equnr
                     action     = ls_log-action
                     status     = ls_log-status
                     msg        = ls_log-msg
                     created_by = sy-uname
                     created_at = lv_now ) ).

  " Simulationen sind nach der naechsten wertlos: je Los nur die letzte
  " behalten. Echtlaeufe bleiben als Nachweis stehen.
  IF iv_test = abap_true.
    DELETE FROM /enercon/qm009_l WHERE prueflos = @iv_prueflos
                                  AND testmode = @abap_true.
  ENDIF.

  INSERT /enercon/qm009_l FROM TABLE @lt_db.
  COMMIT WORK.

  ev_run_id = lv_run_id.

ENDFUNCTION.
