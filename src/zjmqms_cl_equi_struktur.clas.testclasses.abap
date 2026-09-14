CLASS ltc_resolve_parents DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES tt_levels TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    METHODS nodes_from_levels
      IMPORTING it_levels       TYPE tt_levels
      RETURNING VALUE(rt_nodes) TYPE zjmqms_cl_equi_struktur=>tt_node.

    METHODS parents_of
      IMPORTING it_nodes          TYPE zjmqms_cl_equi_struktur=>tt_node
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
    zjmqms_cl_equi_struktur=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = parents_of( lt_nodes )
      exp = VALUE tt_levels( ( 0 ) ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 4 )
                             ( 3 ) ( 3 ) ( 3 ) ( 3 ) ( 2 ) ) ).
  ENDMETHOD.

  METHOD nur_wurzel.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ) ).
    zjmqms_cl_equi_struktur=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_initial( lt_nodes[ 1 ]-parent_seqnumber ).
  ENDMETHOD.

  METHOD ebenensprung.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ( 2 ) ) ).
    zjmqms_cl_equi_struktur=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_initial(
      act = lt_nodes[ 2 ]-parent_seqnumber
      msg = 'Ebene 2 direkt unter Ebene 0 darf keine Elternzeile bekommen' ).
  ENDMETHOD.

  METHOD zweite_wurzel.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ( 1 ) ( 0 ) ( 1 ) ) ).
    zjmqms_cl_equi_struktur=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = parents_of( lt_nodes )
      exp = VALUE tt_levels( ( 0 ) ( 1 ) ( 0 ) ( 3 ) ) ).
  ENDMETHOD.

  METHOD rueckkehr_nach_oben.
    DATA(lt_nodes) = nodes_from_levels( VALUE #( ( 0 ) ( 1 ) ( 2 ) ( 1 ) ( 2 ) ) ).
    zjmqms_cl_equi_struktur=>resolve_parents( CHANGING ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = parents_of( lt_nodes )
      exp = VALUE tt_levels( ( 0 ) ( 1 ) ( 2 ) ( 1 ) ( 4 ) ) ).
  ENDMETHOD.

ENDCLASS.
