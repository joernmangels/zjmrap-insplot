*"* Test-Include (CCAU) fuer ZJMQMS_CL_LOT_EQUI.
*"* In Eclipse: Klasse oeffnen, Reiter "Test Classes", Inhalt einfuegen, aktivieren.
CLASS ltc_material_of_text DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS nummer_mit_text FOR TESTING.       " '1076780 Rotorblatt links'
    METHODS nummer_allein FOR TESTING.         " '1076797'
    METHODS text_ohne_nummer FOR TESTING.      " 'Sichtpruefung Gehaeuse'
    METHODS zu_kurz FOR TESTING.               " '12345'
    METHODS fuehrende_leerzeichen FOR TESTING. " '   1076780 Generator'
ENDCLASS.


CLASS ltc_material_of_text IMPLEMENTATION.

  METHOD nummer_mit_text.
    cl_abap_unit_assert=>assert_equals(
      act = zjmqms_cl_lot_equi=>material_of_text( '1076780 Rotorblatt links' )
      exp = CONV matnr( '000000000001076780' ) ).
  ENDMETHOD.

  METHOD nummer_allein.
    cl_abap_unit_assert=>assert_equals(
      act = zjmqms_cl_lot_equi=>material_of_text( '1076797' )
      exp = CONV matnr( '000000000001076797' ) ).
  ENDMETHOD.

  METHOD text_ohne_nummer.
    cl_abap_unit_assert=>assert_initial(
      act = zjmqms_cl_lot_equi=>material_of_text( 'Sichtpruefung Gehaeuse' )
      msg = 'Text ohne fuehrende Nummer darf kein Material liefern' ).
  ENDMETHOD.

  METHOD zu_kurz.
    cl_abap_unit_assert=>assert_initial(
      act = zjmqms_cl_lot_equi=>material_of_text( '12345' ) ).
  ENDMETHOD.

  METHOD fuehrende_leerzeichen.
    cl_abap_unit_assert=>assert_equals(
      act = zjmqms_cl_lot_equi=>material_of_text( '   1076780 Generator' )
      exp = CONV matnr( '000000000001076780' ) ).
  ENDMETHOD.

ENDCLASS.
