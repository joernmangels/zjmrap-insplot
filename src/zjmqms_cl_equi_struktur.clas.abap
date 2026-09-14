"! Baut die Equipment-Hierarchie eines Pruefloses nach der Soll-Struktur
"! aus ZJMQM_QM009_Q auf.
"!
"! Die Struktur wird ueber ZJMQMS_I_EQUISTRUK gelesen (Ebene und Material
"! je Zeile bereits berechnet). Elternzeile einer Zeile ist die letzte
"! vorangegangene Zeile mit Ebene - 1. Das Equipment einer Zeile ist das
"! Equipment, das ZJMQMS_CL_LOT_EQUI fuer dasselbe Material geliefert hat.
"! Eingebaut wird mit BAPI_EQUI_INSTALL ins uebergeordnete Equipment.
"!
"! Kein Ausbau: sitzt ein Equipment bereits woanders, wird nur gemeldet.
CLASS zjmqms_cl_equi_struktur DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_node,
             seqnumber        TYPE zjmqm_qm009_q-lfdnr,
             ebene            TYPE i,
             matnr            TYPE matnr,
             parent_seqnumber TYPE zjmqm_qm009_q-lfdnr,
           END OF ty_node,
           tt_node TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.

    METHODS constructor
      IMPORTING is_qals TYPE qals
                it_equi TYPE zjmqms_cl_lot_equi=>tt_equi
                iv_test TYPE abap_bool DEFAULT abap_true.

    METHODS run
      RETURNING VALUE(rt_log) TYPE zjmqms_cl_lot_equi=>tt_log.

    "! Elternzeile je Zeile aus der Ebenenfolge. Reine Logik, ohne
    "! Datenbank - deshalb statisch und testbar.
    "!
    "! Zeilen muessen nach laufender Nummer sortiert sein. Eine Zeile mit
    "! Ebene 0 bekommt keine Elternzeile; eine Zeile, deren Ebene mehr als
    "! eins ueber der Vorgaengerzeile liegt, ebenfalls nicht (die
    "! Plausibilitaetspruefung der App warnt genau davor).
    CLASS-METHODS resolve_parents
      CHANGING ct_nodes TYPE tt_node.

  PRIVATE SECTION.

    CONSTANTS c_max_level TYPE i VALUE 19.

    DATA ms_qals TYPE qals.
    DATA mt_equi TYPE zjmqms_cl_lot_equi=>tt_equi.
    DATA mv_test TYPE abap_bool.
    DATA mt_log  TYPE zjmqms_cl_lot_equi=>tt_log.

    METHODS read_structure
      RETURNING VALUE(rt_nodes) TYPE tt_node.

    "! Equipment zum Material aus dem Ergebnis von ZJMQMS_CL_LOT_EQUI.
    "! ev_count > 1 heisst: Material kommt mehrfach vor, Zuordnung unklar.
    METHODS equipment_of_material
      IMPORTING iv_matnr TYPE matnr
      EXPORTING ev_equnr TYPE equnr
                ev_count TYPE i.

    METHODS current_superior
      IMPORTING iv_equnr        TYPE equnr
      RETURNING VALUE(rv_hequi) TYPE equnr.

    METHODS install
      IMPORTING iv_equnr         TYPE equnr
                iv_supequi       TYPE equnr
      RETURNING VALUE(rs_return) TYPE bapiret2.

    METHODS add_log
      IMPORTING is_node   TYPE ty_node
                iv_equnr  TYPE equnr OPTIONAL
                iv_action TYPE string
                iv_status TYPE symsgty
                iv_msg    TYPE string.

ENDCLASS.



CLASS zjmqms_cl_equi_struktur IMPLEMENTATION.


  METHOD constructor.
    ms_qals = is_qals.
    mt_equi = it_equi.
    mv_test = iv_test.
  ENDMETHOD.


  METHOD resolve_parents.

    " Merkt je Ebene die zuletzt gesehene Zeile: Index = Ebene + 1
    DATA lt_last TYPE STANDARD TABLE OF zjmqm_qm009_q-lfdnr WITH EMPTY KEY.

    LOOP AT ct_nodes ASSIGNING FIELD-SYMBOL(<node>).

      CLEAR <node>-parent_seqnumber.

      IF <node>-ebene > 0.
        " Elternzeile = zuletzt gesehene Zeile der Ebene darueber
        READ TABLE lt_last INDEX <node>-ebene INTO <node>-parent_seqnumber.
        IF sy-subrc <> 0.
          CLEAR <node>-parent_seqnumber.
        ENDIF.
      ENDIF.

      " Tiefere Ebenen verlieren ihre Gueltigkeit, diese Ebene wird gesetzt
      DATA(lv_from) = <node>-ebene + 2.
      IF lv_from <= lines( lt_last ).
        DELETE lt_last FROM lv_from.
      ENDIF.

      WHILE lines( lt_last ) < <node>-ebene + 1.
        APPEND INITIAL LINE TO lt_last.
      ENDWHILE.

      lt_last[ <node>-ebene + 1 ] = <node>-seqnumber.

    ENDLOOP.

  ENDMETHOD.


  METHOD run.

    CLEAR mt_log.

    DATA(lt_nodes) = read_structure( ).

    IF lt_nodes IS INITIAL.
      add_log( is_node   = VALUE #( )
               iv_action = zjmqms_cl_lot_equi=>c_action-skipped
               iv_status = 'W'
               iv_msg    = |Keine Strukturvorgabe in ZJMQM_QM009_Q fuer Plan | &&
                           |{ ms_qals-plnty } { ms_qals-plnnr ALPHA = OUT } / { ms_qals-plnal }, | &&
                           |Zaehler { ms_qals-zaehl ALPHA = OUT }| ).
      rt_log = mt_log.
      RETURN.
    ENDIF.

    resolve_parents( CHANGING ct_nodes = lt_nodes ).

    LOOP AT lt_nodes INTO DATA(ls_node).

      " ---- Equipment dieser Zeile --------------------------------------
      equipment_of_material( EXPORTING iv_matnr = ls_node-matnr
                             IMPORTING ev_equnr = DATA(lv_equnr)
                                       ev_count = DATA(lv_count) ).

      IF lv_count = 0.
        add_log( is_node   = ls_node
                 iv_action = zjmqms_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Kein Equipment zu Material { ls_node-matnr ALPHA = OUT } aus dem Los| ).
        CONTINUE.
      ENDIF.

      IF lv_count > 1.
        add_log( is_node   = ls_node
                 iv_action = zjmqms_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Material { ls_node-matnr ALPHA = OUT } kommt { lv_count }-mal im Los vor, | &&
                             |Zuordnung nicht eindeutig| ).
        CONTINUE.
      ENDIF.

      " ---- Wurzel: nichts einzubauen -----------------------------------
      IF ls_node-ebene = 0.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = 'Wurzel'
                 iv_status = 'S'
                 iv_msg    = |Wurzel der Struktur, kein Einbau| ).
        CONTINUE.
      ENDIF.

      IF ls_node-parent_seqnumber IS INITIAL.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = zjmqms_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Keine Elternzeile auf Ebene { ls_node-ebene - 1 } - Ebenensprung in der Vorgabe| ).
        CONTINUE.
      ENDIF.

      " ---- Equipment der Elternzeile -----------------------------------
      DATA(ls_parent) = lt_nodes[ seqnumber = ls_node-parent_seqnumber ].

      equipment_of_material( EXPORTING iv_matnr = ls_parent-matnr
                             IMPORTING ev_equnr = DATA(lv_supequi)
                                       ev_count = DATA(lv_parent_count) ).

      IF lv_parent_count <> 1.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = zjmqms_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Kein eindeutiges Equipment zur Elternzeile { ls_parent-seqnumber ALPHA = OUT } | &&
                             |(Material { ls_parent-matnr ALPHA = OUT })| ).
        CONTINUE.
      ENDIF.

      " ---- Testmodus: Equipments existieren noch nicht ------------------
      IF mv_test = abap_true.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = 'wuerde eingebaut'
                 iv_status = 'S'
                 iv_msg    = |Testmodus: Material { ls_node-matnr ALPHA = OUT } wuerde in | &&
                             |Material { ls_parent-matnr ALPHA = OUT } (Zeile { ls_parent-seqnumber ALPHA = OUT }) eingebaut| ).
        CONTINUE.
      ENDIF.

      IF lv_equnr IS INITIAL OR lv_supequi IS INITIAL.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = zjmqms_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Equipmentnummer fehlt - Anlage im ersten Schritt fehlgeschlagen?| ).
        CONTINUE.
      ENDIF.

      " ---- Ist-Zustand pruefen -----------------------------------------
      DATA(lv_current) = current_superior( lv_equnr ).

      IF lv_current = lv_supequi.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = zjmqms_cl_lot_equi=>c_action-exists
                 iv_status = 'S'
                 iv_msg    = |Bereits in Equipment { lv_supequi ALPHA = OUT } eingebaut| ).
        CONTINUE.
      ENDIF.

      IF lv_current IS NOT INITIAL.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = zjmqms_cl_lot_equi=>c_action-skipped
                 iv_status = 'W'
                 iv_msg    = |Sitzt in Equipment { lv_current ALPHA = OUT }, erwartet { lv_supequi ALPHA = OUT } - | &&
                             |kein automatischer Ausbau| ).
        CONTINUE.
      ENDIF.

      " ---- Einbauen ----------------------------------------------------
      DATA(ls_return) = install( iv_equnr   = lv_equnr
                                 iv_supequi = lv_supequi ).

      IF ls_return-type CA 'EAX'.
        add_log( is_node   = ls_node
                 iv_equnr  = lv_equnr
                 iv_action = zjmqms_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = CONV string( ls_return-message ) ).
        CONTINUE.
      ENDIF.

      add_log( is_node   = ls_node
               iv_equnr  = lv_equnr
               iv_action = 'eingebaut'
               iv_status = 'S'
               iv_msg    = |In Equipment { lv_supequi ALPHA = OUT } eingebaut| ).

    ENDLOOP.

    rt_log = mt_log.

  ENDMETHOD.


  METHOD read_structure.

    " Ebene 99 markiert in der Sicht eine Zeile ohne Material - ueberspringen
    SELECT SeqNumber AS seqnumber,
           Ebene     AS ebene,
           Material  AS matnr
      FROM zjmqms_i_equistruk
      WHERE PlanType     = @ms_qals-plnty
        AND PlanGroup    = @ms_qals-plnnr
        AND GroupCounter = @ms_qals-plnal
        AND NodeCounter  = @ms_qals-zaehl
        AND Ebene       <= @c_max_level
      ORDER BY SeqNumber
      INTO CORRESPONDING FIELDS OF TABLE @rt_nodes.

  ENDMETHOD.


  METHOD equipment_of_material.

    CLEAR: ev_equnr, ev_count.

    LOOP AT mt_equi INTO DATA(ls_equi) WHERE matnr = iv_matnr.
      ev_count = ev_count + 1.
      ev_equnr = ls_equi-equnr.
    ENDLOOP.

    IF ev_count <> 1.
      CLEAR ev_equnr.
    ENDIF.

  ENDMETHOD.


  METHOD current_superior.
    " Aktuell gueltiger Einbauort (Zeitsegment bis 31.12.9999)
    SELECT SINGLE hequi FROM equz
      WHERE equnr = @iv_equnr
        AND datbi = '99991231'
      INTO @rv_hequi.
  ENDMETHOD.


  METHOD install.

    DATA(ls_install) = VALUE bapi_itob_eq_install_ext( supequi   = iv_supequi
                                                       inst_date = sy-datum
                                                       inst_time = sy-uzeit ).

    CALL FUNCTION 'BAPI_EQUI_INSTALL'
      EXPORTING
        equipment    = iv_equnr
        data_install = ls_install
      IMPORTING
        return       = rs_return.

    IF rs_return-type CA 'EAX'.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.

  ENDMETHOD.


  METHOD add_log.
    APPEND VALUE zjmqms_cl_lot_equi=>ty_log(
             prueflos = ms_qals-prueflos
             step     = zjmqms_cl_lot_equi=>c_step-struk
             matnr    = is_node-matnr
             equnr    = iv_equnr
             action   = iv_action
             status   = iv_status
             msg      = COND #( WHEN is_node-seqnumber IS INITIAL
                                THEN iv_msg
                                ELSE |Zeile { is_node-seqnumber ALPHA = OUT } (Ebene { is_node-ebene }): { iv_msg }| ) )
           TO mt_log.
  ENDMETHOD.

ENDCLASS.

