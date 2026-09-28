CLASS lhc_lot DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Lot RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ Lot RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Lot.

    METHODS aufbauen FOR MODIFY
      IMPORTING keys FOR ACTION Lot~aufbauen RESULT result.
ENDCLASS.


CLASS lhc_lot IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Wie der Report: keine eigene Pruefung, die Bausteine darunter
    " pruefen beim Anlegen und Einbauen selbst
    IF requested_authorizations-%action-aufbauen = if_abap_behv=>mk-on.
      result-%action-aufbauen = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.


  METHOD read.
    CHECK keys IS NOT INITIAL.

    SELECT * FROM zjmqms_i_lot
      FOR ALL ENTRIES IN @keys
      WHERE Prueflos = @keys-Prueflos
      INTO TABLE @DATA(lt_lot).

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_lot INTO DATA(ls_lot) WITH KEY Prueflos = ls_key-Prueflos.
      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_lot ) TO result.
      ELSE.
        APPEND VALUE #( %tky        = ls_key-%tky
                        %fail-cause = if_abap_behv=>cause-not_found ) TO failed-lot.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD lock.
    " Bewusst leer: Eine Sperre hier gehoerte dieser Sitzung, der Lauf
    " arbeitet aber in der RFC-Sitzung und wuerde sich selbst aussperren.
    " Die BAPIs dort sperren Equipments und Serialnummern selbst.
    RETURN.
  ENDMETHOD.


  METHOD aufbauen.
    DATA lv_run_id  TYPE sysuuid_x16.
    DATA lv_rfc_msg TYPE c LENGTH 255.

    " Mehrere Lose nacheinander, nicht parallel (Laufzeit, siehe PLAN.md)
    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lv_run_id, lv_rfc_msg.

      " Eigene LUW: Der Baustein committet, das waere hier verboten
      CALL FUNCTION 'ZJMQMS_RUN_STRUKTUR' DESTINATION 'NONE'
        EXPORTING
          iv_prueflos           = ls_key-Prueflos
          iv_test               = xsdbool( ls_key-%param-Echtlauf <> abap_true )
        IMPORTING
          ev_run_id             = lv_run_id
        EXCEPTIONS
          system_failure        = 1 MESSAGE lv_rfc_msg
          communication_failure = 2 MESSAGE lv_rfc_msg
          OTHERS                = 3.
      DATA(lv_subrc) = sy-subrc.

      " Frische RFC-Sitzung je Los, damit keine BAPI-Puffer ins naechste reichen
      CALL FUNCTION 'RFC_CONNECTION_CLOSE'
        EXPORTING
          destination = 'NONE'
        EXCEPTIONS
          OTHERS      = 1.

      IF lv_subrc <> 0 OR lv_run_id IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-lot.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = COND #( WHEN lv_rfc_msg IS NOT INITIAL
                                                    THEN |Prüflos { ls_key-Prueflos ALPHA = OUT }: { lv_rfc_msg }|
                                                    ELSE |Prüflos { ls_key-Prueflos ALPHA = OUT }: Lauf nicht gestartet| ) ) )
               TO reported-lot.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky         = ls_key-%tky
                      %param-RunId = lv_run_id ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_zjmqms_i_lot DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save              REDEFINITION.
    METHODS cleanup           REDEFINITION.
    METHODS cleanup_finalize  REDEFINITION.
ENDCLASS.


CLASS lsc_zjmqms_i_lot IMPLEMENTATION.

  METHOD finalize.
    RETURN.
  ENDMETHOD.

  METHOD check_before_save.
    RETURN.
  ENDMETHOD.

  METHOD save.
    " Nichts zu sichern: ZJMQMS_RUN_STRUKTUR hat in eigener LUW committet
    RETURN.
  ENDMETHOD.

  METHOD cleanup.
    RETURN.
  ENDMETHOD.

  METHOD cleanup_finalize.
    RETURN.
  ENDMETHOD.

ENDCLASS.
