"! Baut die Equipment-Hierarchie eines Pruefloses nach der Soll-Struktur
"! aus /ENERCON/QM009_Q auf.
"!
"! Die Struktur wird ueber /ENERCON/QM009_I_EQUISTRUK gelesen (Ebene und Material
"! je Zeile bereits berechnet). Elternzeile einer Zeile ist die letzte
"! vorangegangene Zeile mit Ebene - 1.
"!
"! Eine Strukturzeile ist eine Vorlage: sie bekommt ALLE Equipments ihres
"! Materials aus dem Los. Beim Einbau gilt zwischen Kind- und Elternzeile
"! 1:n (ein Eltern-Equipment nimmt alle Kinder) oder n:n (paarweise in
"! Reihenfolge); alles andere ist unklar und wird gemeldet. Dieselbe Regel
"! gilt, wenn ein Material mehrfach in der Struktur steht.
"! Eindeutig sein muss nur Material + Serialnummer im Los.
"!
"! Kein Ausbau: sitzt ein Equipment bereits woanders, wird nur gemeldet.
CLASS /enercon/qm009_cl_equi_struk DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_node,
             seqnumber        TYPE /enercon/qm009_q-lfdnr,
             ebene            TYPE i,
             matnr            TYPE matnr,
             parent_seqnumber TYPE /enercon/qm009_q-lfdnr,
             equis            TYPE /enercon/qm009_cl_lot_equi=>tt_equi,
             ambiguous        TYPE abap_bool,
           END OF ty_node,
           tt_node TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.

    METHODS constructor
      IMPORTING is_qals TYPE qals
                it_equi TYPE /enercon/qm009_cl_lot_equi=>tt_equi
                iv_test TYPE abap_bool DEFAULT abap_true.

    METHODS run
      RETURNING VALUE(rt_log) TYPE /enercon/qm009_cl_lot_equi=>tt_log.

    "! Elternzeile je Zeile aus der Ebenenfolge. Reine Logik, ohne
    "! Datenbank - deshalb statisch und testbar.
    "!
    "! Zeilen muessen nach laufender Nummer sortiert sein. Eine Zeile mit
    "! Ebene 0 bekommt keine Elternzeile; eine Zeile, deren Ebene mehr als
    "! eins ueber der Vorgaengerzeile liegt, ebenfalls nicht (die
    "! Plausibilitaetspruefung der App warnt genau davor).
    CLASS-METHODS resolve_parents
      CHANGING ct_nodes TYPE tt_node.

    "! Verteilt die Equipments des Loses auf die Strukturzeilen ihres
    "! Materials: eine Zeile bekommt alle, gleich viele Zeilen bekommen je
    "! eines in Reihenfolge, sonst werden die Zeilen als unklar markiert.
    "! Equipments ohne Strukturzeile kommen in et_unassigned.
    CLASS-METHODS assign_equipments
      IMPORTING it_equi       TYPE /enercon/qm009_cl_lot_equi=>tt_equi
      EXPORTING et_unassigned TYPE /enercon/qm009_cl_lot_equi=>tt_equi
      CHANGING  ct_nodes      TYPE tt_node.

    "! Eltern-Equipment fuer das iv_index-te von iv_count Kind-Equipments:
    "! ein Eltern-Equipment nimmt alle Kinder, gleich viele werden paarweise
    "! zugeordnet. Initial, wenn die Zuordnung unklar ist.
    CLASS-METHODS parent_for_child
      IMPORTING it_parents       TYPE /enercon/qm009_cl_lot_equi=>tt_equi
                iv_index         TYPE i
                iv_count         TYPE i
      RETURNING VALUE(rs_parent) TYPE /enercon/qm009_cl_lot_equi=>ty_equi.

  PRIVATE SECTION.

    CONSTANTS c_max_level TYPE i VALUE 19.

    DATA ms_qals TYPE qals.
    DATA mt_equi TYPE /enercon/qm009_cl_lot_equi=>tt_equi.
    DATA mv_test TYPE abap_bool.
    DATA mt_log  TYPE /enercon/qm009_cl_lot_equi=>tt_log.

    METHODS read_structure
      RETURNING VALUE(rt_nodes) TYPE tt_node.

    "! Erstes Equipment (Material + Serialnummer), das mehrfach aus dem Los
    "! kommt. Initial, wenn alle eindeutig sind.
    METHODS find_duplicate
      RETURNING VALUE(rs_dup) TYPE /enercon/qm009_cl_lot_equi=>ty_equi.

    METHODS install_children
      IMPORTING is_node   TYPE ty_node
                is_parent TYPE ty_node.

    METHODS install_one
      IMPORTING is_node   TYPE ty_node
                is_equi   TYPE /enercon/qm009_cl_lot_equi=>ty_equi
                is_parent TYPE ty_node
                is_supequi TYPE /enercon/qm009_cl_lot_equi=>ty_equi.

    METHODS current_superior
      IMPORTING iv_equnr        TYPE equnr
      RETURNING VALUE(rv_hequi) TYPE equnr.

    METHODS install
      IMPORTING iv_equnr         TYPE equnr
                iv_supequi       TYPE equnr
      RETURNING VALUE(rs_return) TYPE bapiret2.

    METHODS add_log
      IMPORTING is_node   TYPE ty_node
                is_equi   TYPE /enercon/qm009_cl_lot_equi=>ty_equi OPTIONAL
                iv_action TYPE string
                iv_status TYPE symsgty
                iv_msg    TYPE string.

ENDCLASS.



CLASS /enercon/qm009_cl_equi_struk IMPLEMENTATION.


  METHOD constructor.
    ms_qals = is_qals.
    mt_equi = it_equi.
    mv_test = iv_test.
  ENDMETHOD.


  METHOD resolve_parents.

    " Merkt je Ebene die zuletzt gesehene Zeile: Index = Ebene + 1
    DATA lt_last TYPE STANDARD TABLE OF /enercon/qm009_q-lfdnr WITH EMPTY KEY.

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


  METHOD assign_equipments.

    CLEAR et_unassigned.

    LOOP AT ct_nodes ASSIGNING FIELD-SYMBOL(<node>)
         GROUP BY ( matnr = <node>-matnr size = GROUP SIZE ) INTO DATA(ls_group).

      " Alle Equipments dieses Materials, in Vorgangsreihenfolge
      DATA(lt_equi_mat) = VALUE /enercon/qm009_cl_lot_equi=>tt_equi(
                            FOR ls_equi IN it_equi WHERE ( matnr = ls_group-matnr ) ( ls_equi ) ).

      DATA(lv_index) = 0.

      LOOP AT GROUP ls_group ASSIGNING FIELD-SYMBOL(<row>).
        CLEAR: <row>-equis, <row>-ambiguous.
        lv_index = lv_index + 1.

        IF ls_group-size = 1.
          " Eine Zeile: nimmt alle Equipments
          <row>-equis = lt_equi_mat.
        ELSEIF ls_group-size = lines( lt_equi_mat ).
          " Gleich viele Zeilen wie Equipments: eins je Zeile
          APPEND lt_equi_mat[ lv_index ] TO <row>-equis.
        ELSEIF lt_equi_mat IS NOT INITIAL.
          <row>-ambiguous = abap_true.
        ENDIF.
      ENDLOOP.

    ENDLOOP.

    " Equipments, deren Material gar nicht in der Struktur steht
    LOOP AT it_equi INTO DATA(ls_free).
      IF NOT line_exists( ct_nodes[ matnr = ls_free-matnr ] ).
        APPEND ls_free TO et_unassigned.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD parent_for_child.

    DATA(lv_parents) = lines( it_parents ).

    IF lv_parents = 1.
      rs_parent = it_parents[ 1 ].
    ELSEIF lv_parents = iv_count AND iv_index BETWEEN 1 AND lv_parents.
      rs_parent = it_parents[ iv_index ].
    ENDIF.

  ENDMETHOD.


  METHOD run.

    CLEAR mt_log.

    " ---- Dieselbe Serialnummer in zwei Vorgaengen: Zuordnung unklar -----
    DATA(ls_dup) = find_duplicate( ).

    IF ls_dup-matnr IS NOT INITIAL.
      add_log( is_node   = VALUE #( matnr = ls_dup-matnr )
               is_equi   = ls_dup
               iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
               iv_status = 'E'
               iv_msg    = |Serialnummer { ls_dup-sernr } zu Material { ls_dup-matnr ALPHA = OUT } | &&
                           |kommt in mehreren Vorgaengen vor - Struktur nicht aufgebaut| ).
      rt_log = mt_log.
      RETURN.
    ENDIF.

    " ---- Soll-Struktur ----------------------------------------------
    DATA(lt_nodes) = read_structure( ).

    IF lt_nodes IS INITIAL.
      add_log( is_node   = VALUE #( )
               iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
               iv_status = 'W'
               iv_msg    = |Keine Strukturvorgabe in /ENERCON/QM009_Q fuer Plan | &&
                           |{ ms_qals-plnty } { ms_qals-plnnr ALPHA = OUT } / { ms_qals-plnal }, | &&
                           |Zaehler { ms_qals-zaehl ALPHA = OUT }| ).
      rt_log = mt_log.
      RETURN.
    ENDIF.

    resolve_parents( CHANGING ct_nodes = lt_nodes ).

    assign_equipments( EXPORTING it_equi       = mt_equi
                       IMPORTING et_unassigned = DATA(lt_unassigned)
                       CHANGING  ct_nodes      = lt_nodes ).

    LOOP AT lt_unassigned INTO DATA(ls_free).
      add_log( is_node   = VALUE #( matnr = ls_free-matnr )
               is_equi   = ls_free
               iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
               iv_status = 'W'
               iv_msg    = |Vorgang { ls_free-vornr }: Material { ls_free-matnr ALPHA = OUT } | &&
                           |steht nicht in der Struktur - Equipment bleibt ohne Einbau| ).
    ENDLOOP.

    " ---- Einbau je Zeile ---------------------------------------------
    LOOP AT lt_nodes INTO DATA(ls_node).

      IF ls_node-ambiguous = abap_true.
        DATA(lv_rows)  = REDUCE i( INIT n = 0 FOR r IN lt_nodes WHERE ( matnr = ls_node-matnr ) NEXT n = n + 1 ).
        DATA(lv_equis) = REDUCE i( INIT n = 0 FOR e IN mt_equi  WHERE ( matnr = ls_node-matnr ) NEXT n = n + 1 ).
        add_log( is_node   = ls_node
                 iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Material { ls_node-matnr ALPHA = OUT }: { lv_rows } Strukturzeilen, | &&
                             |{ lv_equis } Equipments im Los - Zuordnung unklar| ).
        CONTINUE.
      ENDIF.

      IF ls_node-equis IS INITIAL.
        add_log( is_node   = ls_node
                 iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Kein Equipment zu Material { ls_node-matnr ALPHA = OUT } im Los| ).
        CONTINUE.
      ENDIF.

      IF ls_node-ebene = 0.
        LOOP AT ls_node-equis INTO DATA(ls_root).
          add_log( is_node   = ls_node
                   is_equi   = ls_root
                   iv_action = 'Wurzel'
                   iv_status = 'S'
                   iv_msg    = |Wurzel der Struktur, kein Einbau| ).
        ENDLOOP.
        CONTINUE.
      ENDIF.

      IF ls_node-parent_seqnumber IS INITIAL.
        add_log( is_node   = ls_node
                 iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Keine Elternzeile auf Ebene { ls_node-ebene - 1 } - Ebenensprung in der Vorgabe| ).
        CONTINUE.
      ENDIF.

      DATA(ls_parent) = lt_nodes[ seqnumber = ls_node-parent_seqnumber ].

      IF ls_parent-equis IS INITIAL.
        add_log( is_node   = ls_node
                 iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |Elternzeile { ls_parent-seqnumber ALPHA = OUT } | &&
                             |(Material { ls_parent-matnr ALPHA = OUT }) hat kein Equipment| ).
        CONTINUE.
      ENDIF.

      install_children( is_node   = ls_node
                        is_parent = ls_parent ).

    ENDLOOP.

    rt_log = mt_log.

  ENDMETHOD.


  METHOD install_children.

    DATA(lv_count) = lines( is_node-equis ).

    LOOP AT is_node-equis INTO DATA(ls_equi).
      DATA(lv_index) = sy-tabix.

      DATA(ls_supequi) = parent_for_child( it_parents = is_parent-equis
                                           iv_index   = lv_index
                                           iv_count   = lv_count ).

      IF ls_supequi IS INITIAL.
        add_log( is_node   = is_node
                 is_equi   = ls_equi
                 iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
                 iv_status = 'E'
                 iv_msg    = |{ lv_count } Equipments, Elternzeile { is_parent-seqnumber ALPHA = OUT } | &&
                             |hat { lines( is_parent-equis ) } - Zuordnung unklar| ).
        CONTINUE.
      ENDIF.

      install_one( is_node    = is_node
                   is_equi    = ls_equi
                   is_parent  = is_parent
                   is_supequi = ls_supequi ).
    ENDLOOP.

  ENDMETHOD.


  METHOD install_one.

    " ---- Testmodus: Equipments existieren noch nicht ------------------
    IF mv_test = abap_true.
      add_log( is_node   = is_node
               is_equi   = is_equi
               iv_action = 'wuerde eingebaut'
               iv_status = 'S'
               iv_msg    = |Testmodus: wuerde in Material { is_parent-matnr ALPHA = OUT } / | &&
                           |Serialnummer { is_supequi-sernr } (Zeile { is_parent-seqnumber ALPHA = OUT }) eingebaut| ).
      RETURN.
    ENDIF.

    IF is_equi-equnr IS INITIAL OR is_supequi-equnr IS INITIAL.
      add_log( is_node   = is_node
               is_equi   = is_equi
               iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
               iv_status = 'E'
               iv_msg    = |Equipmentnummer fehlt - Anlage im ersten Schritt fehlgeschlagen?| ).
      RETURN.
    ENDIF.

    " ---- Ist-Zustand pruefen -----------------------------------------
    DATA(lv_current) = current_superior( is_equi-equnr ).

    IF lv_current = is_supequi-equnr.
      add_log( is_node   = is_node
               is_equi   = is_equi
               iv_action = /enercon/qm009_cl_lot_equi=>c_action-exists
               iv_status = 'S'
               iv_msg    = |Bereits in Equipment { is_supequi-equnr ALPHA = OUT } eingebaut| ).
      RETURN.
    ENDIF.

    IF lv_current IS NOT INITIAL.
      add_log( is_node   = is_node
               is_equi   = is_equi
               iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
               iv_status = 'W'
               iv_msg    = |Sitzt in Equipment { lv_current ALPHA = OUT }, erwartet | &&
                           |{ is_supequi-equnr ALPHA = OUT } - kein automatischer Ausbau| ).
      RETURN.
    ENDIF.

    " ---- Einbauen ----------------------------------------------------
    DATA(ls_return) = install( iv_equnr   = is_equi-equnr
                               iv_supequi = is_supequi-equnr ).

    IF ls_return-type CA 'EAX'.
      add_log( is_node   = is_node
               is_equi   = is_equi
               iv_action = /enercon/qm009_cl_lot_equi=>c_action-skipped
               iv_status = 'E'
               iv_msg    = CONV string( ls_return-message ) ).
      RETURN.
    ENDIF.

    add_log( is_node   = is_node
             is_equi   = is_equi
             iv_action = 'eingebaut'
             iv_status = 'S'
             iv_msg    = |In Equipment { is_supequi-equnr ALPHA = OUT } eingebaut| ).

  ENDMETHOD.


  METHOD read_structure.

    " Ebene 99 markiert in der Sicht eine Zeile ohne Material - ueberspringen
    SELECT SeqNumber AS seqnumber,
           Ebene     AS ebene,
           Material  AS matnr
      FROM /enercon/qm009_i_equistruk
      WHERE PlanType     = @ms_qals-plnty
        AND PlanGroup    = @ms_qals-plnnr
        AND GroupCounter = @ms_qals-plnal
        AND NodeCounter  = @ms_qals-zaehl
        AND Ebene       <= @c_max_level
      ORDER BY SeqNumber
      INTO CORRESPONDING FIELDS OF TABLE @rt_nodes.

  ENDMETHOD.


  METHOD find_duplicate.

    DATA lt_seen TYPE SORTED TABLE OF /enercon/qm009_cl_lot_equi=>ty_equi
                 WITH UNIQUE KEY matnr sernr.

    LOOP AT mt_equi INTO DATA(ls_equi).
      INSERT ls_equi INTO TABLE lt_seen.
      IF sy-subrc <> 0.
        rs_dup = ls_equi.
        RETURN.
      ENDIF.
    ENDLOOP.

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
    APPEND VALUE /enercon/qm009_cl_lot_equi=>ty_log(
             prueflos = ms_qals-prueflos
             step     = /enercon/qm009_cl_lot_equi=>c_step-struk
             vornr    = is_equi-vornr
             matnr    = is_node-matnr
             sernr    = is_equi-sernr
             equnr    = is_equi-equnr
             action   = iv_action
             status   = iv_status
             " ALPHA = OUT auf 40-stelligen Feldern laesst Leerzeichen
             " stehen: vor Satzzeichen entfernen, sonst auf eins kuerzen
             msg      = condense( replace(
                            val  = COND string( WHEN is_node-seqnumber IS INITIAL
                                                THEN iv_msg
                                                ELSE |Zeile { is_node-seqnumber ALPHA = OUT } (Ebene { is_node-ebene }): { iv_msg }| )
                            pcre = `\s+(?=[,.:;)])`
                            with = ``
                            occ  = 0 ) ) )
           TO mt_log.
  ENDMETHOD.

ENDCLASS.

