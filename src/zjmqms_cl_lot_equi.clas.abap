"! Legt zu einem Pruefplos je Vorgang eine Serialnummer bzw. ein Equipment an.
"!
"! Steuerung ueber ZJMQM_QM009_E (Schluessel: Losmaterial, Werk, Pruefart,
"! Herkunft): SERNR_HEAD_VORG nennt den Vorgang des Losmaterials,
"! SERNR_HEAD_MERKMAL das Merkmal, dessen erfasster Wert die Serialnummer ist,
"! PREFIX_SERNR wird jeder Serialnummer vorangestellt. Das Merkmal gilt fuer
"! alle Vorgaenge; bei den uebrigen Vorgaengen liefert der Kurztext (erste
"! sieben Stellen) das Material.
"!
"! Bereits vorhandene Equipments (EQUI zu Material + Serialnummer) werden
"! wiederverwendet, der Lauf ist damit wiederholbar.
CLASS zjmqms_cl_lot_equi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_log,
             prueflos TYPE qals-prueflos,
             step     TYPE c LENGTH 5,
             vornr    TYPE vornr,
             matnr    TYPE matnr,
             sernr    TYPE gernr,
             equnr    TYPE equnr,
             action   TYPE string,
             status   TYPE symsgty,
             msg      TYPE string,
           END OF ty_log,
           tt_log TYPE STANDARD TABLE OF ty_log WITH EMPTY KEY.

    TYPES: BEGIN OF ty_equi,
             vornr  TYPE vornr,
             matnr  TYPE matnr,
             sernr  TYPE gernr,
             equnr  TYPE equnr,
             action TYPE string,
           END OF ty_equi,
           tt_equi TYPE STANDARD TABLE OF ty_equi WITH EMPTY KEY.

    CONSTANTS: BEGIN OF c_step,
                 equi  TYPE ty_log-step VALUE 'EQUI',
                 struk TYPE ty_log-step VALUE 'STRUK',
               END OF c_step.

    CONSTANTS: BEGIN OF c_action,
                 created   TYPE string VALUE 'angelegt',
                 exists    TYPE string VALUE 'vorhanden',
                 simulated TYPE string VALUE 'wuerde angelegt',
                 skipped   TYPE string VALUE 'uebersprungen',
               END OF c_action.

    METHODS constructor
      IMPORTING iv_prueflos TYPE qals-prueflos
                iv_test     TYPE abap_bool DEFAULT abap_true.

    "! Verarbeitet alle Vorgaenge und liefert je Vorgang Material,
    "! Serialnummer und Equipment. Details stehen im Protokoll (get_log).
    METHODS run
      RETURNING VALUE(rt_equi) TYPE tt_equi.

    METHODS get_lot
      RETURNING VALUE(rs_qals) TYPE qals.

    METHODS get_log
      RETURNING VALUE(rt_log) TYPE tt_log.

    "! Materialnummer aus den ersten sieben Stellen eines Vorgangskurztexts.
    "! Oeffentlich und statisch, damit sie ohne Los testbar ist.
    CLASS-METHODS material_of_text
      IMPORTING iv_text         TYPE clike
      RETURNING VALUE(rv_matnr) TYPE matnr.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_operation,
             vorglfnr TYPE qamv-vorglfnr,
             vornr    TYPE vornr,
             vorktxt  TYPE qapo-vorktxt,
           END OF ty_operation,
           tt_operation TYPE STANDARD TABLE OF ty_operation WITH EMPTY KEY.

    CONSTANTS c_matnr_len_in_text TYPE i VALUE 7.

    DATA mv_prueflos TYPE qals-prueflos.
    DATA mv_test     TYPE abap_bool.
    DATA ms_qals     TYPE qals.
    DATA ms_control  TYPE zjmqm_qm009_e.
    DATA mt_log      TYPE tt_log.

    METHODS read_lot
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    METHODS read_control
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    METHODS read_operations
      RETURNING VALUE(rt_ops) TYPE tt_operation.

    METHODS is_head_operation
      IMPORTING iv_vornr          TYPE vornr
      RETURNING VALUE(rv_is_head) TYPE abap_bool.

    METHODS material_exists
      IMPORTING iv_matnr         TYPE matnr
      RETURNING VALUE(rv_exists) TYPE abap_bool.

    "! Erfasster Wert des Serialnummern-Merkmals im Vorgang. Zuerst
    "! QASE-ORIGINAL_INPUT (Zeichenkette, keine Gleitkomma-Umwege),
    "! ersatzweise ueber BAPI_INSPCHAR_GETRESULT.
    METHODS serial_of_operation
      IMPORTING iv_vorglfnr     TYPE qamv-vorglfnr
                iv_vornr        TYPE vornr
      RETURNING VALUE(rv_value) TYPE string.

    METHODS find_equipment
      IMPORTING iv_matnr        TYPE matnr
                iv_sernr        TYPE gernr
      RETURNING VALUE(rv_equnr) TYPE equnr.

    METHODS create_equipment
      IMPORTING iv_matnr  TYPE matnr
                iv_sernr  TYPE gernr
      EXPORTING ev_equnr  TYPE equnr
                et_return TYPE bapirettab.

    METHODS add_log
      IMPORTING is_equi   TYPE ty_equi
                iv_status TYPE symsgty
                iv_msg    TYPE string.

ENDCLASS.



CLASS zjmqms_cl_lot_equi IMPLEMENTATION.


  METHOD constructor.
    mv_prueflos = iv_prueflos.
    mv_test     = iv_test.
  ENDMETHOD.


  METHOD get_lot.
    rs_qals = ms_qals.
  ENDMETHOD.


  METHOD get_log.
    rt_log = mt_log.
  ENDMETHOD.


  METHOD material_of_text.

    DATA(lv_text) = CONV string( iv_text ).
    CONDENSE lv_text.

    IF strlen( lv_text ) < c_matnr_len_in_text.
      RETURN.
    ENDIF.

    DATA(lv_raw) = lv_text(c_matnr_len_in_text).

    " Blank im Materialteil: der Kurztext beginnt nicht mit einer Nummer
    IF lv_raw CA space.
      RETURN.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING  input        = lv_raw
      IMPORTING  output       = rv_matnr
      EXCEPTIONS length_error = 1
                 OTHERS       = 2.
    IF sy-subrc <> 0.
      CLEAR rv_matnr.
    ENDIF.

  ENDMETHOD.


  METHOD run.

    CLEAR: rt_equi, mt_log.

    IF read_lot( ) = abap_false OR read_control( ) = abap_false.
      RETURN.
    ENDIF.

    DATA(lt_ops) = read_operations( ).

    IF lt_ops IS INITIAL.
      add_log( is_equi   = VALUE #( action = c_action-skipped )
               iv_status = 'E'
               iv_msg    = |Pruefplos { mv_prueflos ALPHA = OUT } hat keine Vorgaenge| ).
      RETURN.
    ENDIF.

    DATA(lv_head_found) = abap_false.

    LOOP AT lt_ops INTO DATA(ls_op).

      DATA(ls_equi) = VALUE ty_equi( vornr = ls_op-vornr ).

      " ---- Material des Vorgangs ---------------------------------------
      IF is_head_operation( ls_op-vornr ) = abap_true.
        ls_equi-matnr = ms_qals-matnr.
        lv_head_found = abap_true.
      ELSE.
        ls_equi-matnr = material_of_text( ls_op-vorktxt ).

        IF ls_equi-matnr IS INITIAL.
          ls_equi-action = c_action-skipped.
          add_log( is_equi   = ls_equi
                   iv_status = 'W'
                   iv_msg    = |Kurztext "{ ls_op-vorktxt }" beginnt nicht mit einer Materialnummer| ).
          CONTINUE.
        ENDIF.

        IF material_exists( ls_equi-matnr ) = abap_false.
          ls_equi-action = c_action-skipped.
          add_log( is_equi   = ls_equi
                   iv_status = 'E'
                   iv_msg    = |Material { ls_equi-matnr ALPHA = OUT } aus dem Kurztext existiert nicht| ).
          CONTINUE.
        ENDIF.
      ENDIF.

      " ---- Serialnummer aus dem Merkmal --------------------------------
      DATA(lv_value) = serial_of_operation( iv_vorglfnr = ls_op-vorglfnr
                                            iv_vornr    = ls_op-vornr ).

      IF lv_value IS INITIAL.
        ls_equi-action = c_action-skipped.
        add_log( is_equi   = ls_equi
                 iv_status = 'W'
                 iv_msg    = |Merkmal { ms_control-sernr_head_merkmal } hat keinen erfassten Wert| ).
        CONTINUE.
      ENDIF.

      DATA(lv_sernr) = |{ ms_control-prefix_sernr }{ lv_value }|.
      CONDENSE lv_sernr NO-GAPS.

      DATA(lv_len) = strlen( lv_sernr ).
      DESCRIBE FIELD ls_equi-sernr LENGTH DATA(lv_max) IN CHARACTER MODE.

      IF lv_len > lv_max.
        ls_equi-action = c_action-skipped.
        add_log( is_equi   = ls_equi
                 iv_status = 'E'
                 iv_msg    = |Serialnummer "{ lv_sernr }" ist laenger als { lv_max } Stellen| ).
        CONTINUE.
      ENDIF.

      ls_equi-sernr = lv_sernr.

      " ---- Equipment: vorhanden oder anlegen ---------------------------
      ls_equi-equnr = find_equipment( iv_matnr = ls_equi-matnr
                                      iv_sernr = ls_equi-sernr ).

      IF ls_equi-equnr IS NOT INITIAL.
        ls_equi-action = c_action-exists.
        add_log( is_equi   = ls_equi
                 iv_status = 'S'
                 iv_msg    = |Equipment { ls_equi-equnr ALPHA = OUT } bereits vorhanden| ).
        APPEND ls_equi TO rt_equi.
        CONTINUE.
      ENDIF.

      create_equipment( EXPORTING iv_matnr  = ls_equi-matnr
                                  iv_sernr  = ls_equi-sernr
                        IMPORTING ev_equnr  = ls_equi-equnr
                                  et_return = DATA(lt_return) ).

      " Fehlermeldungen des Bausteins durchreichen
      DATA(lv_failed) = abap_false.
      LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'EAX'.
        lv_failed = abap_true.
        ls_equi-action = c_action-skipped.
        add_log( is_equi   = ls_equi
                 iv_status = 'E'
                 iv_msg    = CONV string( ls_return-message ) ).
      ENDLOOP.

      IF lv_failed = abap_true.
        CONTINUE.
      ENDIF.

      IF mv_test = abap_true.
        ls_equi-action = c_action-simulated.
        add_log( is_equi   = ls_equi
                 iv_status = 'S'
                 iv_msg    = |Testmodus: Serialnummer { ls_equi-sernr } wuerde angelegt| ).
        APPEND ls_equi TO rt_equi.
        CONTINUE.
      ENDIF.

      IF ls_equi-equnr IS INITIAL.
        ls_equi-action = c_action-skipped.
        add_log( is_equi   = ls_equi
                 iv_status = 'E'
                 iv_msg    = |Serialnummer { ls_equi-sernr } angelegt, aber kein Equipment gefunden| ).
        CONTINUE.
      ENDIF.

      ls_equi-action = c_action-created.
      add_log( is_equi   = ls_equi
               iv_status = 'S'
               iv_msg    = |Equipment { ls_equi-equnr ALPHA = OUT } angelegt| ).
      APPEND ls_equi TO rt_equi.

    ENDLOOP.

    IF lv_head_found = abap_false.
      add_log( is_equi   = VALUE #( vornr  = ms_control-sernr_head_vorg
                                    matnr  = ms_qals-matnr
                                    action = c_action-skipped )
               iv_status = 'W'
               iv_msg    = |Kopfvorgang { ms_control-sernr_head_vorg } laut ZJMQM_QM009_E nicht im Los| ).
    ENDIF.

  ENDMETHOD.


  METHOD read_lot.

    SELECT SINGLE * FROM qals
      WHERE prueflos = @mv_prueflos
      INTO @ms_qals.

    rv_ok = xsdbool( sy-subrc = 0 ).

    IF rv_ok = abap_false.
      add_log( is_equi   = VALUE #( action = c_action-skipped )
               iv_status = 'E'
               iv_msg    = |Pruefplos { mv_prueflos ALPHA = OUT } nicht gefunden| ).
    ENDIF.

  ENDMETHOD.


  METHOD read_control.

    SELECT SINGLE * FROM zjmqm_qm009_e
      WHERE matnr    = @ms_qals-matnr
        AND werk     = @ms_qals-werk
        AND art      = @ms_qals-art
        AND herkunft = @ms_qals-herkunft
      INTO @ms_control.

    rv_ok = xsdbool( sy-subrc = 0 ).

    IF rv_ok = abap_false.
      add_log( is_equi   = VALUE #( matnr = ms_qals-matnr action = c_action-skipped )
               iv_status = 'E'
               iv_msg    = |Keine Steuerung in ZJMQM_QM009_E fuer Material { ms_qals-matnr ALPHA = OUT }, | &&
                           |Werk { ms_qals-werk }, Pruefart { ms_qals-art }, Herkunft { ms_qals-herkunft }| ).
      RETURN.
    ENDIF.

    IF ms_control-sernr_head_vorg IS INITIAL OR ms_control-sernr_head_merkmal IS INITIAL.
      rv_ok = abap_false.
      add_log( is_equi   = VALUE #( matnr = ms_qals-matnr action = c_action-skipped )
               iv_status = 'E'
               iv_msg    = |Steuerung unvollstaendig: Kopfvorgang oder Serialnummern-Merkmal fehlt| ).
    ENDIF.

  ENDMETHOD.


  METHOD read_operations.

    " Die Vorgaenge eines Loses stehen im Pruefplan; die freigegebene Sicht
    " loest das auf. VORGLFNR ist der interne Knoten, ueber den QASE/QAMV
    " die Merkmale zuordnen.
    SELECT InspPlanOperationInternalID AS vorglfnr,
           InspectionOperation         AS vornr,
           OperationText               AS vorktxt
      FROM I_InspectionOperation
      WHERE InspectionLot = @mv_prueflos
      ORDER BY InspectionOperation
      INTO CORRESPONDING FIELDS OF TABLE @rt_ops.

  ENDMETHOD.


  METHOD is_head_operation.
    " Beide Seiten numerisch vergleichen: '10' und '0010' meinen denselben Vorgang
    rv_is_head = xsdbool( CONV numc4( iv_vornr ) = CONV numc4( ms_control-sernr_head_vorg ) ).
  ENDMETHOD.


  METHOD material_exists.
    SELECT SINGLE @abap_true FROM mara
      WHERE matnr = @iv_matnr
      INTO @rv_exists.
  ENDMETHOD.


  METHOD serial_of_operation.

    DATA lv_merknr TYPE qase-merknr.
    lv_merknr = ms_control-sernr_head_merkmal.

    " Einzelwerte: der urspruenglich erfasste Wert als Zeichenkette
    SELECT original_input
      FROM qase
      WHERE prueflos = @mv_prueflos
        AND vorglfnr = @iv_vorglfnr
        AND merknr   = @lv_merknr
        AND original_input <> @space
      ORDER BY PRIMARY KEY
      INTO @DATA(lv_original)
      UP TO 1 ROWS.
    ENDSELECT.

    IF sy-subrc = 0.
      rv_value = condense( lv_original ).
      RETURN.
    ENDIF.

    " Ersatz: Ergebnis ueber die BAPI lesen
    DATA lt_single TYPE STANDARD TABLE OF bapi2045d4 WITH EMPTY KEY.

    CALL FUNCTION 'BAPI_INSPCHAR_GETRESULT'
      EXPORTING
        insplot        = mv_prueflos
        inspoper       = iv_vornr
        inspchar       = lv_merknr
      TABLES
        single_results = lt_single.

    LOOP AT lt_single INTO DATA(ls_single) WHERE res_value IS NOT INITIAL.
      rv_value = condense( CONV string( ls_single-res_value ) ).
      RETURN.
    ENDLOOP.

  ENDMETHOD.


  METHOD find_equipment.
    SELECT SINGLE equnr FROM equi
      WHERE matnr = @iv_matnr
        AND sernr = @iv_sernr
      INTO @rv_equnr.
  ENDMETHOD.


  METHOD create_equipment.

    CLEAR: ev_equnr, et_return.

    CALL FUNCTION 'ZJMQM009_ASGN_SERNR_PL_2'
      EXPORTING
        iv_plos   = mv_prueflos
        iv_matnr  = iv_matnr
        iv_sernr  = iv_sernr
        iv_test   = mv_test
      IMPORTING
        et_return = et_return.

    IF mv_test = abap_true.
      RETURN.
    ENDIF.

    ev_equnr = find_equipment( iv_matnr = iv_matnr
                               iv_sernr = iv_sernr ).

  ENDMETHOD.


  METHOD add_log.
    APPEND VALUE ty_log( prueflos = mv_prueflos
                         step     = c_step-equi
                         vornr    = is_equi-vornr
                         matnr    = is_equi-matnr
                         sernr    = is_equi-sernr
                         equnr    = is_equi-equnr
                         action   = is_equi-action
                         status   = iv_status
                         " ALPHA = OUT auf 40-stelligen Feldern laesst Leerzeichen
                         " stehen: vor Satzzeichen entfernen, sonst auf eins kuerzen
                         msg      = condense( replace( val  = iv_msg
                                                       pcre = `\s+(?=[,.:;)])`
                                                       with = ``
                                                       occ  = 0 ) ) )
           TO mt_log.
  ENDMETHOD.

ENDCLASS.

