FUNCTION zjmqm009_asgn_sernr_pl_2.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IV_PLOS) TYPE  QALS-PRUEFLOS
*"     VALUE(IV_MATNR) TYPE  EQUI-MATNR
*"     VALUE(IV_SERNR) TYPE  GERNR
*"     VALUE(IV_TEST) TYPE  CHAR1 OPTIONAL
*"  EXPORTING
*"     VALUE(ET_RETURN) TYPE  BAPIRETTAB
*"----------------------------------------------------------------------
  CONSTANTS:
    lc_serialprofile TYPE t377p-serail  VALUE 'Z001',
    lc_taser_ser04   TYPE objk-taser    VALUE 'SER04',
    lc_beleg_qmsl    TYPE t377x-beleg   VALUE 'QMSL'.

  DATA:
    ls_qals        TYPE qals,
    lt_smesg       TYPE tsmesg,
    lt_da_sernos   TYPE STANDARD TABLE OF e1rmsno,
    lt_da_r_sernos TYPE STANDARD TABLE OF ersernr,
    lv_anzahl      TYPE risa0-anzahl,     "Numbers Serial Numbe
    ls_serxx       TYPE rserxx,           "Header data
    lt_ser04       TYPE TABLE OF ser04,
    lv_sernr       TYPE gernr,
    ls_ret2        TYPE bapiret2.

** Serialnummern prüfen
*  LOOP AT it_sernr INTO lv_sernr.
*    SELECT a~obknr a~prueflos a~datum a~uzeit a~anzsn a~vorgang
*         INTO CORRESPONDING FIELDS OF TABLE lt_ser04
*         FROM ser04 AS a INNER JOIN objk AS b
*         ON a~obknr = b~obknr
*         WHERE a~prueflos = iv_plos
*         AND   b~matnr = iv_matnr
*         AND   b~sernr = lv_sernr
*         AND   b~taser = lc_taser_ser04.
*
*    IF NOT sy-subrc IS INITIAL.
**      SELECT * FROM equi
**               APPENDING CORRESPONDING FIELDS OF TABLE lt_da_sernos
**               WHERE matnr = iv_matnr
**               AND   sernr = lv_sernr.
* "#EC CI_ALL_FIELDS_NEEDED (FUNCTION actual parameter)     "$smart: #712
*    ENDIF.
*  ENDLOOP.

** keine Serialnummern?
*  lv_anzahl = lines( lt_da_sernos ).                                                             "$smart: #164
*  IF lv_anzahl = 0.
*    MESSAGE e004(/enercon/qm009) INTO ls_ret2-message.
*    ls_ret2-type       = 'E'.
*    ls_ret2-id         = '/ENERCON/QM009'.
*    ls_ret2-number     = '004'.
*    APPEND ls_ret2 TO et_return.
*    RETURN.
*  ENDIF.
  IF lv_anzahl = 0.
    lv_anzahl = 1.
  ENDIF.
* Prüflos sperren
  CALL FUNCTION 'ENQUEUE_EQQALS1'
    EXPORTING
      prueflos       = iv_plos
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  IF NOT sy-subrc IS INITIAL.
*    MESSAGE i295(qa) WITH iv_plos.
    CLEAR ls_ret2.
    MESSAGE i295(qa) INTO ls_ret2-message WITH iv_plos.
    ls_ret2-type       = 'E'.
    ls_ret2-id         = 'QA'.
    ls_ret2-number     = '295'.
    ls_ret2-message_v1 = iv_plos.
    APPEND ls_ret2 TO et_return.
    RETURN.
  ENDIF.

* Prüflos lesen
  SELECT SINGLE * FROM qals INTO ls_qals WHERE prueflos = iv_plos.                               "$smart: #712
 "#EC CI_ALL_FIELDS_NEEDED (FUNCTION actual parameter)                                        "$smart: #712
  CHECK sy-subrc IS INITIAL.
  APPEND iv_sernr TO lt_da_sernos.
* verarbeiten
  MOVE iv_plos TO ls_serxx-prueflos.
  CALL FUNCTION 'SERIAL_INTTAB_REFRESH'.
  CALL FUNCTION 'SERNR_ADD_TO_DOCUMENT'
    EXPORTING
      operation = lc_beleg_qmsl
      objkopf   = lc_taser_ser04
      serxx     = ls_serxx
      material  = iv_matnr
      quantity  = lv_anzahl
      profile   = lc_serialprofile
    TABLES
      sernr     = lt_da_sernos
      r_sernr   = lt_da_r_sernos
    CHANGING
      t_smesg   = lt_smesg.
  IF iv_test IS INITIAL.
* buchen
    CALL FUNCTION 'SERIAL_LISTE_POST_QM'.

* Anzahl Serialnummern anpasssen
    ls_qals-anzsn = lv_anzahl.
    CALL FUNCTION 'QEBU_QALS_POSTING_SERIAL'
      EXPORTING
        i_qals = ls_qals.

* jetzt auf DB
    COMMIT WORK AND WAIT.
  ENDIF.




ENDFUNCTION.
