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


CLASS ltc_assign_equipments DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES tt_matnr TYPE STANDARD TABLE OF matnr WITH EMPTY KEY.
    TYPES tt_sernr TYPE STANDARD TABLE OF gernr WITH EMPTY KEY.

    METHODS nodes_from_materials
      IMPORTING it_matnr        TYPE tt_matnr
      RETURNING VALUE(rt_nodes) TYPE zjmqms_cl_equi_struktur=>tt_node.

    METHODS serials_of
      IMPORTING it_nodes         TYPE zjmqms_cl_equi_struktur=>tt_node
      RETURNING VALUE(rt_serials) TYPE tt_sernr.

    METHODS gleiches_material_mehrfach FOR TESTING. " 3x Rotorblatt -> 3 Serialnummern
    METHODS reihenfolge_der_vorgaenge FOR TESTING.  " n-te Zeile = n-tes Equipment
    METHODS zeile_ohne_equipment FOR TESTING.       " mehr Zeilen als Equipments
    METHODS equipment_ohne_zeile FOR TESTING.       " mehr Equipments als Zeilen
ENDCLASS.


CLASS ltc_assign_equipments IMPLEMENTATION.

  METHOD nodes_from_materials.
    LOOP AT it_matnr INTO DATA(lv_matnr).
      APPEND VALUE #( seqnumber = sy-tabix
                      matnr     = lv_matnr ) TO rt_nodes.
    ENDLOOP.
  ENDMETHOD.

  METHOD serials_of.
    LOOP AT it_nodes INTO DATA(ls_node).
      APPEND ls_node-sernr TO rt_serials.
    ENDLOOP.
  ENDMETHOD.

  METHOD gleiches_material_mehrfach.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'NABE' ) ( 'BLATT' ) ( 'BLATT' ) ( 'BLATT' ) ) ).

    zjmqms_cl_equi_struktur=>assign_equipments(
      EXPORTING it_equi       = VALUE #( ( vornr = '0010' matnr = 'NABE'  sernr = 'N1' equnr = '1' )
                                         ( vornr = '0020' matnr = 'BLATT' sernr = 'B1' equnr = '2' )
                                         ( vornr = '0030' matnr = 'BLATT' sernr = 'B2' equnr = '3' )
                                         ( vornr = '0040' matnr = 'BLATT' sernr = 'B3' equnr = '4' ) )
      IMPORTING et_unassigned = DATA(lt_free)
      CHANGING  ct_nodes      = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = serials_of( lt_nodes )
      exp = VALUE tt_sernr( ( 'N1' ) ( 'B1' ) ( 'B2' ) ( 'B3' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lt_nodes[ 3 ]-equnr exp = '3' ).
    cl_abap_unit_assert=>assert_initial( lt_free ).
  ENDMETHOD.

  METHOD reihenfolge_der_vorgaenge.
    " Equipments kommen in Vorgangsreihenfolge; die erste Zeile bekommt das erste
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'BLATT' ) ( 'BLATT' ) ) ).

    zjmqms_cl_equi_struktur=>assign_equipments(
      EXPORTING it_equi  = VALUE #( ( vornr = '0010' matnr = 'BLATT' sernr = 'SPAET' )
                                    ( vornr = '0020' matnr = 'BLATT' sernr = 'FRUEH' ) )
      CHANGING  ct_nodes = lt_nodes ).

    cl_abap_unit_assert=>assert_equals(
      act = serials_of( lt_nodes )
      exp = VALUE tt_sernr( ( 'SPAET' ) ( 'FRUEH' ) ) ).
  ENDMETHOD.

  METHOD zeile_ohne_equipment.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'BLATT' ) ( 'BLATT' ) ) ).

    zjmqms_cl_equi_struktur=>assign_equipments(
      EXPORTING it_equi       = VALUE #( ( vornr = '0010' matnr = 'BLATT' sernr = 'B1' ) )
      IMPORTING et_unassigned = DATA(lt_free)
      CHANGING  ct_nodes      = lt_nodes ).

    cl_abap_unit_assert=>assert_equals( act = lt_nodes[ 1 ]-sernr exp = 'B1' ).
    cl_abap_unit_assert=>assert_initial(
      act = lt_nodes[ 2 ]-sernr
      msg = 'Zweite Zeile darf kein Equipment bekommen, es gibt nur eines' ).
    cl_abap_unit_assert=>assert_initial( lt_free ).
  ENDMETHOD.

  METHOD equipment_ohne_zeile.
    DATA(lt_nodes) = nodes_from_materials( VALUE #( ( 'BLATT' ) ) ).

    zjmqms_cl_equi_struktur=>assign_equipments(
      EXPORTING it_equi       = VALUE #( ( vornr = '0010' matnr = 'BLATT' sernr = 'B1' )
                                         ( vornr = '0020' matnr = 'BLATT' sernr = 'B2' )
                                         ( vornr = '0030' matnr = 'FREMD' sernr = 'F1' ) )
      IMPORTING et_unassigned = DATA(lt_free)
      CHANGING  ct_nodes      = lt_nodes ).

    cl_abap_unit_assert=>assert_equals( act = lt_nodes[ 1 ]-sernr exp = 'B1' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_free ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_free[ 1 ]-sernr exp = 'B2' ).
    cl_abap_unit_assert=>assert_equals( act = lt_free[ 2 ]-sernr exp = 'F1' ).
  ENDMETHOD.

ENDCLASS.
