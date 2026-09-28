CLASS ltc_resolve_parents DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES tt_levels TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    METHODS nodes_from_levels
      IMPORTING it_levels       TYPE tt_levels
      RETURNING VALUE(rt_nodes) TYPE /enercon/qm009_cl_equi_struk=>tt_node.

    METHODS parents_of
      IMPORTING it_nodes          TYPE /enercon/qm009_cl_equi_struk=>tt_node
      RETURNING VALUE(rt_parents) TYPE tt_levels.

    METHODS tiefe_struktur FOR TESTING.      " 0 1 2 3 4 4 3 3 3 3 2
    METHODS nur_wurzel FOR TESTING.          " 0
    METHODS ebenensprung FOR TESTING.        " 0 2 -> Zeile 2 ohne Eltern
    METHODS zweite_wurzel FOR TESTING.       " 0 1 0 1 -> Zeile 4 haengt an Zeile 3
    METHODS rueckkehr_nach_oben FOR TESTING. " 0 1 2 1 2 -> Zeile 5 haengt an Zeile 4
ENDCLASS.


CLASS ltc_resolve_parents IMPLEMENTATION.

  METHOD nodes_from_levels.
    " Laufende Nummer = Position, Material nur zur Unterscheidung
    LOOP AT it_levels INTO DATA(lv_level).
      APPEND VALUE #( seqnumber = sy-tabix
                      ebene     = lv_level
                      matnr     = |M{ sy-tabix }| ) TO rt_nodes.
    ENDLOOP.
  ENDMETHOD.

  METHOD parents_of.
    LOOP AT it_nodes INTO DATA(ls_node).
      APPEND CONV i( ls_node-parent_seqnumber ) TO rt_parents.
    ENDLOOP.
  ENDMETHOD.

  METHOD tiefe_struktur.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 4 )
                                                 ( 3 ) ( 3 ) ( 3 ) ( 3 ) ( 2 ) ) ).
    /enercon/qm009_cl_equi_struk=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = parents_of( lt_nodes )
      exp = VALUE tt_levels( ( 0 ) ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 4 )
                             ( 3 ) ( 3 ) ( 3 ) ( 3 ) ( 2 ) ) ).
  ENDMETHOD.

  METHOD nur_wurzel.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ) ).
    /enercon/qm009_cl_equi_struk=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_initial( lt_nodes[ 1 ]-parent_seqnumber ).
  ENDMETHOD.

  METHOD ebenensprung.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ( 2 ) ) ).
    /enercon/qm009_cl_equi_struk=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_initial(
      act = lt_nodes[ 2 ]-parent_seqnumber
      msg = 'Ebene 2 direkt unter Ebene 0 darf keine Elternzeile bekommen' ).
  ENDMETHOD.

  METHOD zweite_wurzel.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ( 1 ) ( 0 ) ( 1 ) ) ).
    /enercon/qm009_cl_equi_struk=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = parents_of( lt_nodes )
      exp = VALUE tt_levels( ( 0 ) ( 1 ) ( 0 ) ( 3 ) ) ).
  ENDMETHOD.

  METHOD rueckkehr_nach_oben.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ( 1 ) ( 2 ) ( 1 ) ( 2 ) ) ).
    /enercon/qm009_cl_equi_struk=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = parents_of( lt_nodes )
      exp = VALUE tt_levels( ( 0 ) ( 1 ) ( 2 ) ( 1 ) ( 4 ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_assign_equipments DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES tt_matnr TYPE STANDARD TABLE OF matnr WITH EMPTY KEY.
    TYPES tt_sernr TYPE STANDARD TABLE OF gernr WITH EMPTY KEY.

    METHODS nodes_from_materials
      IMPORTING it_matnr        TYPE tt_matnr
      RETURNING VALUE(rt_nodes) TYPE /enercon/qm009_cl_equi_struk=>tt_node.

    METHODS serials_of
      IMPORTING it_equis         TYPE /enercon/qm009_cl_lot_equi=>tt_equi
      RETURNING VALUE(rt_serials) TYPE tt_sernr.

    METHODS eine_zeile_alle_equipments FOR TESTING. " 1 Zeile, 3 Equipments -> alle drei
    METHODS gleich_viele_zeilen FOR TESTING.        " 2 Zeilen, 2 Equipments -> je eins in Reihenfolge
    METHODS zuordnung_unklar FOR TESTING.           " 2 Zeilen, 3 Equipments -> unklar
    METHODS zeile_ohne_equipment FOR TESTING.       " kein Equipment -> leer, nicht unklar
    METHODS equipment_ohne_zeile FOR TESTING.       " Material fehlt in der Struktur
ENDCLASS.


CLASS ltc_assign_equipments IMPLEMENTATION.

  METHOD nodes_from_materials.
    LOOP AT it_matnr INTO DATA(lv_matnr).
      APPEND VALUE #( seqnumber = sy-tabix
                      matnr     = lv_matnr ) TO rt_nodes.
    ENDLOOP.
  ENDMETHOD.

  METHOD serials_of.
    LOOP AT it_equis INTO DATA(ls_equi).
      APPEND ls_equi-sernr TO rt_serials.
    ENDLOOP.
  ENDMETHOD.

  METHOD eine_zeile_alle_equipments.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'NABE' ) ( 'BLATT' ) ) ).

    /enercon/qm009_cl_equi_struk=>assign_equipments(
      EXPORTING it_equi       = VALUE #( ( vornr = '0010' matnr = 'NABE'  sernr = 'N1' )
                                         ( vornr = '0020' matnr = 'BLATT' sernr = 'B1' )
                                         ( vornr = '0030' matnr = 'BLATT' sernr = 'B2' )
                                         ( vornr = '0040' matnr = 'BLATT' sernr = 'B3' ) )
      IMPORTING et_unassigned = DATA(lt_free)
      CHANGING  ct_nodes      = lt_nodes ).

    cl_abap_unit_assert=>assert_equals( act = serials_of( lt_nodes[ 1 ]-equis )
                                        exp = VALUE tt_sernr( ( 'N1' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = serials_of( lt_nodes[ 2 ]-equis )
                                        exp = VALUE tt_sernr( ( 'B1' ) ( 'B2' ) ( 'B3' ) ) ).
    cl_abap_unit_assert=>assert_initial( lt_nodes[ 2 ]-ambiguous ).
    cl_abap_unit_assert=>assert_initial( lt_free ).
  ENDMETHOD.

  METHOD gleich_viele_zeilen.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'BLATT' ) ( 'BLATT' ) ) ).

    /enercon/qm009_cl_equi_struk=>assign_equipments(
      EXPORTING it_equi  = VALUE #( ( vornr = '0010' matnr = 'BLATT' sernr = 'ERSTES' )
                                    ( vornr = '0020' matnr = 'BLATT' sernr = 'ZWEITES' ) )
      CHANGING  ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals( act = serials_of( lt_nodes[ 1 ]-equis )
                                        exp = VALUE tt_sernr( ( 'ERSTES' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = serials_of( lt_nodes[ 2 ]-equis )
                                        exp = VALUE tt_sernr( ( 'ZWEITES' ) ) ).
  ENDMETHOD.

  METHOD zuordnung_unklar.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'BLATT' ) ( 'BLATT' ) ) ).

    /enercon/qm009_cl_equi_struk=>assign_equipments(
      EXPORTING it_equi  = VALUE #( ( vornr = '0010' matnr = 'BLATT' sernr = 'B1' )
                                    ( vornr = '0020' matnr = 'BLATT' sernr = 'B2' )
                                    ( vornr = '0030' matnr = 'BLATT' sernr = 'B3' ) )
      CHANGING  ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_true( lt_nodes[ 1 ]-ambiguous ).
    cl_abap_unit_assert=>assert_true( lt_nodes[ 2 ]-ambiguous ).
    cl_abap_unit_assert=>assert_initial( lt_nodes[ 1 ]-equis ).
  ENDMETHOD.

  METHOD zeile_ohne_equipment.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'BLATT' ) ( 'KAPPE' ) ) ).

    /enercon/qm009_cl_equi_struk=>assign_equipments(
      EXPORTING it_equi       = VALUE #( ( vornr = '0010' matnr = 'BLATT' sernr = 'B1' ) )
      IMPORTING et_unassigned = DATA(lt_free)
      CHANGING  ct_nodes      = lt_nodes ).

    cl_abap_unit_assert=>assert_initial( act = lt_nodes[ 2 ]-equis
                                         msg = 'KAPPE hat kein Equipment im Los' ).
    cl_abap_unit_assert=>assert_initial( lt_nodes[ 2 ]-ambiguous ).
    cl_abap_unit_assert=>assert_initial( lt_free ).
  ENDMETHOD.

  METHOD equipment_ohne_zeile.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'BLATT' ) ) ).

    /enercon/qm009_cl_equi_struk=>assign_equipments(
      EXPORTING it_equi       = VALUE #( ( vornr = '0010' matnr = 'BLATT' sernr = 'B1' )
                                         ( vornr = '0020' matnr = 'FREMD' sernr = 'F1' ) )
      IMPORTING et_unassigned = DATA(lt_free)
      CHANGING  ct_nodes      = lt_nodes ).

    cl_abap_unit_assert=>assert_equals( act = serials_of( lt_free )
                                        exp = VALUE tt_sernr( ( 'F1' ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_parent_for_child DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS ein_elternteil_nimmt_alle FOR TESTING. " 1 Eltern, 3 Kinder -> immer dasselbe
    METHODS paarweise FOR TESTING.                 " 3 Eltern, 3 Kinder -> i-tes zu i-tem
    METHODS unklar FOR TESTING.                    " 2 Eltern, 3 Kinder -> initial
ENDCLASS.


CLASS ltc_parent_for_child IMPLEMENTATION.

  METHOD ein_elternteil_nimmt_alle.
    DATA(lt_parents) = VALUE /enercon/qm009_cl_lot_equi=>tt_equi( ( sernr = 'P1' ) ).

    DO 3 TIMES.
      cl_abap_unit_assert=>assert_equals(
        act = /enercon/qm009_cl_equi_struk=>parent_for_child( it_parents = lt_parents
                                                          iv_index   = sy-index
                                                          iv_count   = 3 )-sernr
        exp = 'P1' ).
    ENDDO.
  ENDMETHOD.

  METHOD paarweise.
    DATA(lt_parents) = VALUE /enercon/qm009_cl_lot_equi=>tt_equi( ( sernr = 'P1' ) ( sernr = 'P2' ) ( sernr = 'P3' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = /enercon/qm009_cl_equi_struk=>parent_for_child( it_parents = lt_parents
                                                        iv_index   = 2
                                                        iv_count   = 3 )-sernr
      exp = 'P2' ).
  ENDMETHOD.

  METHOD unklar.
    DATA(lt_parents) = VALUE /enercon/qm009_cl_lot_equi=>tt_equi( ( sernr = 'P1' ) ( sernr = 'P2' ) ).

    cl_abap_unit_assert=>assert_initial(
      /enercon/qm009_cl_equi_struk=>parent_for_child( it_parents = lt_parents
                                                  iv_index   = 1
                                                  iv_count   = 3 ) ).
  ENDMETHOD.

ENDCLASS.
