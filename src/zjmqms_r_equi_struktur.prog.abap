*&---------------------------------------------------------------------*
*& Report ZJMQMS_R_EQUI_STRUKTUR
*&---------------------------------------------------------------------*
*& Legt je Pruefplos-Vorgang Serialnummer/Equipment an und baut die
*& Equipments nach der Vorgabe aus ZJMQM_QM009_Q ineinander ein.
*&
*& Schritt 1: ZJMQMS_CL_LOT_EQUI      (Serialnummern, Equipments)
*& Schritt 2: ZJMQMS_CL_EQUI_STRUKTUR (Einbau nach Soll-Struktur)
*&
*& Testmodus (Vorbelegung): nur lesen und protokollieren.
*&---------------------------------------------------------------------*
REPORT zjmqms_r_equi_struktur.

TABLES qals.

" Rahmentitel als Variablen (werden durch FRAME TITLE implizit deklariert):
" Textelemente sind ueber die ADT-Schnittstelle dieses Systems nicht pflegbar
SELECTION-SCREEN BEGIN OF BLOCK sel WITH FRAME TITLE gv_tsel.
  SELECT-OPTIONS s_plos  FOR qals-prueflos OBLIGATORY.
  SELECT-OPTIONS s_werk  FOR qals-werk.
  SELECT-OPTIONS s_datum FOR qals-enstehdat.
SELECTION-SCREEN END OF BLOCK sel.

SELECTION-SCREEN BEGIN OF BLOCK opt WITH FRAME TITLE gv_topt.
  PARAMETERS p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK opt.

INITIALIZATION.
  gv_tsel = 'Prüflose'.
  gv_topt = 'Ausführung (Testmodus = nur protokollieren)'.

CLASS lcl_report DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS run.

  PRIVATE SECTION.
    TYPES tt_prueflos TYPE STANDARD TABLE OF qals-prueflos WITH EMPTY KEY.

    DATA mt_log TYPE zjmqms_cl_lot_equi=>tt_log.

    METHODS select_lots
      RETURNING VALUE(rt_lots) TYPE tt_prueflos.

    METHODS process_lot
      IMPORTING iv_prueflos TYPE qals-prueflos.

    METHODS display.
ENDCLASS.


CLASS lcl_report IMPLEMENTATION.

  METHOD run.
    DATA(lt_lots) = select_lots( ).

    IF lt_lots IS INITIAL.
      MESSAGE 'Keine Prueflose zur Selektion gefunden' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " Fehler in einem Los brechen die uebrigen nicht ab
    LOOP AT lt_lots INTO DATA(lv_prueflos).
      process_lot( lv_prueflos ).
    ENDLOOP.

    display( ).
  ENDMETHOD.


  METHOD select_lots.
    SELECT prueflos FROM qals
      WHERE prueflos  IN @s_plos
        AND werk      IN @s_werk
        AND enstehdat IN @s_datum
      ORDER BY prueflos
      INTO TABLE @rt_lots.
  ENDMETHOD.


  METHOD process_lot.

    DATA(lo_lot) = NEW zjmqms_cl_lot_equi( iv_prueflos = iv_prueflos
                                           iv_test     = p_test ).
    DATA(lt_equi) = lo_lot->run( ).
    APPEND LINES OF lo_lot->get_log( ) TO mt_log.

    " Ohne Equipments gibt es nichts einzubauen (Los nicht gefunden,
    " keine Steuerung, keine Serialnummern)
    IF lt_equi IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_struktur) = NEW zjmqms_cl_equi_struktur( is_qals = lo_lot->get_lot( )
                                                     it_equi = lt_equi
                                                     iv_test = p_test ).
    APPEND LINES OF lo_struktur->run( ) TO mt_log.

  ENDMETHOD.


  METHOD display.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
                                CHANGING  t_table      = mt_log ).
      CATCH cx_salv_msg INTO DATA(lx_salv).
        MESSAGE lx_salv TYPE 'E'.
    ENDTRY.

    lo_alv->get_functions( )->set_all( ).
    lo_alv->get_columns( )->set_optimize( ).
    lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
    lo_alv->get_display_settings( )->set_list_header(
      COND #( WHEN p_test = abap_true
              THEN 'Equipment-Struktur aus Prueflos - TESTMODUS, keine Aenderungen'
              ELSE 'Equipment-Struktur aus Prueflos' ) ).

    DATA(lo_cols) = lo_alv->get_columns( ).

    TRY.
        DATA(lo_col) = lo_cols->get_column( 'STEP' ).
        lo_col->set_short_text( 'Schritt' ).
        lo_col->set_medium_text( 'Schritt' ).
        lo_col->set_long_text( 'Schritt' ).

        lo_col = lo_cols->get_column( 'ACTION' ).
        lo_col->set_short_text( 'Aktion' ).
        lo_col->set_medium_text( 'Aktion' ).
        lo_col->set_long_text( 'Aktion' ).

        lo_col = lo_cols->get_column( 'STATUS' ).
        lo_col->set_short_text( 'Status' ).
        lo_col->set_medium_text( 'Status' ).
        lo_col->set_long_text( 'Status' ).

        lo_col = lo_cols->get_column( 'MSG' ).
        lo_col->set_short_text( 'Meldung' ).
        lo_col->set_medium_text( 'Meldung' ).
        lo_col->set_long_text( 'Meldung' ).
      CATCH cx_salv_not_found.
        " Spalte fehlt nur, wenn der Protokolltyp geaendert wurde
    ENDTRY.

    lo_alv->display( ).

  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  NEW lcl_report( )->run( ).
