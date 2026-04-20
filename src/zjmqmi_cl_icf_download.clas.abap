CLASS zjmqmi_cl_icf_download DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_code,
             code     TYPE qpct-code,
             kurztext TYPE qpct-kurztext,
           END OF ty_code.
    TYPES ty_codes       TYPE STANDARD TABLE OF ty_code WITH EMPTY KEY.
    TYPES ty_radii_codes TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    TYPES: BEGIN OF ty_row,
             prueflosnummer  TYPE c LENGTH 18,
             plangruppe      TYPE c LENGTH 8,
             pgz             TYPE c LENGTH 2,
             pgz_text        TYPE c LENGTH 40,
             lieferant_nr    TYPE c LENGTH 10,
             bestell_nr      TYPE c LENGTH 10,
             bestell_pos     TYPE c LENGTH 5,
             material        TYPE c LENGTH 18,
             mstae_text      TYPE c LENGTH 40,
             vorgangsnummer  TYPE c LENGTH 4,
             vorgang_text    TYPE c LENGTH 40,
             fhm             TYPE c LENGTH 8,
             fhm_text        TYPE c LENGTH 40,
             stammerkmal     TYPE c LENGTH 8,
             quanqual        TYPE c LENGTH 2,
             merkmalsnummer  TYPE c LENGTH 4,
             kurztext        TYPE c LENGTH 40,
             pruefmethode    TYPE c LENGTH 40,
             sollwert_ql     TYPE c LENGTH 30,
             toleranz_ql     TYPE c LENGTH 4,
             langtext        TYPE string,
             sollwert_qn     TYPE c LENGTH 20,
             toleranz_ob     TYPE c LENGTH 20,
             toleranz_un     TYPE c LENGTH 20,
             losgroesse      TYPE c LENGTH 10,
             qc_department   TYPE c LENGTH 1,
             is_quantitative TYPE abap_bool,
             codes           TYPE ty_codes,
             radii_codes_1   TYPE string,
             radii_codes_2   TYPE string,
           END OF ty_row.
    TYPES ty_data TYPE TABLE OF ty_row WITH EMPTY KEY.

    TYPES: BEGIN OF ty_char,
             inspectionlot                  TYPE qals-prueflos,
             insplanoperationinternalid     TYPE qamv-vorglfnr,
             inspectioncharacteristic       TYPE qamv-merknr,
             inspectionoperation            TYPE c LENGTH 4,
             operationtext                  TYPE c LENGTH 40,
             inspectioncharacteristictext   TYPE c LENGTH 40,
             inspectionmethod               TYPE qamv-pmethode,
             inspectionmethodversion        TYPE qamv-pmtversion,
             inspectionmethodplant          TYPE qamv-qmtb_werks,
             inspectionmethodtext           TYPE c LENGTH 40,
             inspectionspecification        TYPE qamv-verwmerkm,
             selectedcodeset                TYPE qamv-auswmenge1,
             characteristicattributecatalog TYPE qamv-katalgart1,
             inspcharacteristicsamplesize   TYPE qamv-sollstpumf,
             inspspecisquantitative         TYPE c LENGTH 1,
             inspspectargetvalue            TYPE qamv-sollwert,
             inspspecupperlimit             TYPE qamv-toleranzob,
             inspspeclowerlimit             TYPE qamv-toleranzun,
           END OF ty_char.
    TYPES ty_chars TYPE TABLE OF ty_char WITH EMPTY KEY.

    TYPES: BEGIN OF ty_lot_header,
             inspectionlot           TYPE qals-prueflos,
             billofoperationsgroup   TYPE plko-plnnr,
             billofoperationsvariant TYPE plko-plnal,
             billofoperationstype    TYPE plko-plnty,
             supplier                TYPE lfa1-lifnr,
             purchasingdocument      TYPE ekko-ebeln,
             purchasingdocumentitem  TYPE ekpo-ebelp,
             material                TYPE mara-matnr,
           END OF ty_lot_header.

    METHODS _download_single
      IMPORTING server     TYPE REF TO if_http_server
                iv_lot_str TYPE string.

    METHODS _download_batch
      IMPORTING server TYPE REF TO if_http_server.

    METHODS _get_lot_header
      IMPORTING iv_lot        TYPE qals-prueflos
      RETURNING VALUE(rs_hdr) TYPE ty_lot_header.

    METHODS _get_codes
      IMPORTING iv_prueflos     TYPE qals-prueflos
                iv_vorglfnr     TYPE qamv-vorglfnr
                iv_merknr       TYPE qamv-merknr
      RETURNING VALUE(rt_codes) TYPE ty_codes.

    METHODS _get_radii_codes
      IMPORTING iv_prueflos      TYPE qals-prueflos
                iv_vorglfnr      TYPE qamv-vorglfnr
                iv_merknr        TYPE qamv-merknr
      RETURNING VALUE(rt_codes)  TYPE ty_radii_codes.

    METHODS _get_longtext
      IMPORTING iv_prueflos    TYPE qals-prueflos
                iv_vorglfnr    TYPE qamv-vorglfnr
                iv_merknr      TYPE qamv-merknr
      RETURNING VALUE(rv_text) TYPE string.

    METHODS _fill_data
      IMPORTING is_hdr         TYPE ty_lot_header
      RETURNING VALUE(rt_data) TYPE ty_data.

    METHODS _send_xlsx
      IMPORTING server  TYPE REF TO if_http_server
                it_data TYPE ty_data
                iv_name TYPE string.

    METHODS _esc
      IMPORTING iv_val        TYPE string
      RETURNING VALUE(rv_val) TYPE string.

    METHODS _cell
      IMPORTING iv_col        TYPE i
                iv_row        TYPE i
                iv_val        TYPE string
      RETURNING VALUE(rv_xml) TYPE string.

ENDCLASS.

CLASS zjmqmi_cl_icf_download IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA(lv_lot_str) = server->request->get_form_field( `lot` ).
    IF lv_lot_str IS NOT INITIAL.
      _download_single( server = server iv_lot_str = lv_lot_str ).
    ELSE.
      _download_batch( server = server ).
    ENDIF.
  ENDMETHOD.


  METHOD _download_single.
    DATA(lv_lot)  = CONV qals-prueflos( iv_lot_str ).
    DATA(ls_hdr)  = _get_lot_header( lv_lot ).
    DATA(lt_data) = _fill_data( ls_hdr ).

    GET TIME STAMP FIELD DATA(lv_ts).
    MODIFY zjmqmit_status FROM @( VALUE #(
      prueflos   = lv_lot
      last_dl_at = lv_ts
      last_dl_by = sy-uname ) ).
    COMMIT WORK.

    _send_xlsx( server  = server
                it_data = lt_data
                iv_name = |{ condense( iv_lot_str ) }.xlsx| ).
  ENDMETHOD.


  METHOD _download_batch.
    SELECT prueflos FROM zjmqmit_dl_token
      WHERE created_by = @sy-uname
      ORDER BY prueflos
      INTO TABLE @DATA(lt_lots).
    IF lt_lots IS INITIAL.
      server->response->set_status( code = 404 reason = |{ TEXT-028 }| ).
      RETURN.
    ENDIF.

    GET TIME STAMP FIELD DATA(lv_ts).
    DATA lt_data TYPE ty_data.
    LOOP AT lt_lots ASSIGNING FIELD-SYMBOL(<lot>).
      DATA(ls_hdr) = _get_lot_header( <lot>-prueflos ).
      INSERT LINES OF _fill_data( ls_hdr ) INTO TABLE lt_data.
      MODIFY zjmqmit_status FROM @( VALUE #(
        prueflos   = <lot>-prueflos
        last_dl_at = lv_ts
        last_dl_by = sy-uname ) ).
    ENDLOOP.
    DELETE FROM zjmqmit_dl_token WHERE created_by = @sy-uname.
    COMMIT WORK.

    _send_xlsx( server  = server
                it_data = lt_data
                iv_name = |Vormerkliste_{ sy-uname }.xlsx| ).
  ENDMETHOD.


  METHOD _get_lot_header.
    SELECT SINGLE
        InspectionLot, BillOfOperationsGroup, BillOfOperationsVariant,
        BillOfOperationsType, Supplier, PurchasingDocument,
        PurchasingDocumentItem, Material
      FROM I_InspectionLot
      WHERE InspectionLot = @iv_lot
      INTO @DATA(ls_il).
    rs_hdr-inspectionlot           = ls_il-InspectionLot.
    rs_hdr-billofoperationsgroup   = ls_il-BillOfOperationsGroup.
    rs_hdr-billofoperationsvariant = ls_il-BillOfOperationsVariant.
    rs_hdr-billofoperationstype    = ls_il-BillOfOperationsType.
    rs_hdr-supplier                = ls_il-Supplier.
    rs_hdr-purchasingdocument      = ls_il-PurchasingDocument.
    rs_hdr-purchasingdocumentitem  = ls_il-PurchasingDocumentItem.
    rs_hdr-material                = ls_il-Material.
  ENDMETHOD.


  METHOD _get_codes.
    SELECT SINGLE katalgart1, auswmenge1, auswmgwrk1
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @iv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @DATA(ls_qamv).
    CHECK sy-subrc = 0
      AND ls_qamv-katalgart1 IS NOT INITIAL
      AND ls_qamv-auswmenge1 IS NOT INITIAL.
    SELECT qpac~code, qpct~kurztext
      FROM qpac
      INNER JOIN qpct ON  qpct~katalogart = qpac~katalogart
                      AND qpct~codegruppe = qpac~codegruppe
                      AND qpct~code       = qpac~code
                      AND qpct~version    = `000001`
                      AND qpct~sprache    = @sy-langu
      WHERE qpac~katalogart = @ls_qamv-katalgart1
        AND qpac~werks      = @ls_qamv-auswmgwrk1
        AND qpac~auswahlmge = @ls_qamv-auswmenge1
      ORDER BY qpac~code
      INTO CORRESPONDING FIELDS OF TABLE @rt_codes.
  ENDMETHOD.


  METHOD _get_radii_codes.
    SELECT SINGLE katalgart2, auswmenge2
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @iv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @DATA(ls_q).
    CHECK sy-subrc = 0
      AND ls_q-katalgart2 = 'E'
      AND ls_q-auswmenge2 = 'QM'.

    SELECT code, kurztext
      FROM qpct
      WHERE katalogart = @ls_q-katalgart2
        AND codegruppe = @ls_q-auswmenge2
        AND sprache    = @sy-langu
      ORDER BY code ASCENDING
      INTO TABLE @DATA(lt_texts).

    LOOP AT lt_texts INTO DATA(ls_t).
      APPEND condense( ls_t-kurztext ) TO rt_codes.
    ENDLOOP.
  ENDMETHOD.


  METHOD _get_longtext.
    DATA: BEGIN OF ls_key,
            mandt   TYPE sy-mandt,
            werks   TYPE qamkr-qpmk_werks,
            mkmnr   TYPE qamkr-verwmerkm,
            version TYPE qamkr-mkversion,
            sprache TYPE sy-langu,
          END OF ls_key.

    SELECT SINGLE qpmk_werks, verwmerkm, mkversion
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @iv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @DATA(ls_qamv).
    CHECK sy-subrc = 0.

    ls_key-mandt   = sy-mandt.
    ls_key-werks   = ls_qamv-qpmk_werks.
    ls_key-mkmnr   = ls_qamv-verwmerkm.
    ls_key-version = ls_qamv-mkversion.
    ls_key-sprache = sy-langu.

    DATA lt_lines TYPE TABLE OF tline WITH EMPTY KEY.
    DATA(lv_txt_name) = CONV tdobname( ls_key ).
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id       = 'QPMT'
        language = sy-langu
        name     = lv_txt_name
        object   = 'QPMERKMAL '
      TABLES
        lines    = lt_lines
      EXCEPTIONS
        OTHERS   = 8.
    CHECK sy-subrc = 0.

    LOOP AT lt_lines INTO DATA(ls_line) WHERE tdline IS NOT INITIAL.
      rv_text = rv_text && condense( ls_line-tdline ) && ` `.
    ENDLOOP.
    rv_text = condense( rv_text ).
  ENDMETHOD.


  METHOD _fill_data.
    DATA lt_char      TYPE ty_chars.
    DATA ls_row       TYPE ty_row.
    SELECT SINGLE ktext FROM plko
      WHERE plnty = @is_hdr-billofoperationstype
        AND plnnr = @is_hdr-billofoperationsgroup
        AND plnal = @is_hdr-billofoperationsvariant
      INTO @DATA(lv_pgz_text).

    SELECT SINGLE mstae FROM mara
      WHERE matnr = @is_hdr-material
      INTO @DATA(lv_mstae).
    DATA lv_mstae_text TYPE c LENGTH 40.
    IF lv_mstae IS NOT INITIAL.
      SELECT SINGLE mtstb FROM t141t
        WHERE spras = @sy-langu AND mmsta = @lv_mstae
        INTO @lv_mstae_text.
    ENDIF.

    SELECT ic~InspectionLot              AS inspectionlot,
           ic~InspPlanOperationInternalID AS insplanoperationinternalid,
           ic~InspectionCharacteristic    AS inspectioncharacteristic,
           ic~InspectionOperation         AS inspectionoperation,
           ic~OperationText               AS operationtext,
           ic~InspectionCharacteristicText AS inspectioncharacteristictext,
           ic~InspectionMethod            AS inspectionmethod,
           ic~InspectionMethodVersion     AS inspectionmethodversion,
           ic~InspectionMethodPlant       AS inspectionmethodplant,
           ic~InspectionMethodText        AS inspectionmethodtext,
           ic~InspectionSpecification     AS inspectionspecification,
           ic~SelectedCodeSet             AS selectedcodeset,
           ic~CharacteristicAttributeCatalog AS characteristicattributecatalog,
           ic~InspCharacteristicSampleSize AS inspcharacteristicsamplesize,
           ic~InspSpecIsQuantitative      AS inspspecisquantitative,
           ic~InspSpecTargetValue         AS inspspectargetvalue,
           ic~InspSpecUpperLimit          AS inspspecupperlimit,
           ic~InspSpecLowerLimit          AS inspspeclowerlimit
      FROM zjmqmi_i_insplot_char AS ic
      WHERE ic~InspectionLot = @is_hdr-inspectionlot
      ORDER BY ic~InspectionOperation, ic~InspectionCharacteristic
      INTO CORRESPONDING FIELDS OF TABLE @lt_char.

    LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<c>).
      CLEAR ls_row.
      ls_row-prueflosnummer = <c>-inspectionlot.
      ls_row-plangruppe     = is_hdr-billofoperationsgroup.
      ls_row-pgz            = is_hdr-billofoperationsvariant.
      ls_row-pgz_text       = lv_pgz_text.
      ls_row-lieferant_nr   = is_hdr-supplier.
      ls_row-bestell_nr     = is_hdr-purchasingdocument.
      ls_row-bestell_pos    = is_hdr-purchasingdocumentitem.
      ls_row-material       = is_hdr-material.
      ls_row-mstae_text     = lv_mstae_text.
      ls_row-vorgangsnummer = <c>-inspectionoperation.
      ls_row-vorgang_text   = <c>-operationtext.
      ls_row-fhm            = <c>-inspectionmethod.
      ls_row-fhm_text       = <c>-inspectionmethodtext.
      ls_row-stammerkmal    = <c>-inspectionspecification.
      ls_row-quanqual       = COND #( WHEN <c>-inspspecisquantitative = `X` THEN `QN` ELSE `QL` ).
      ls_row-merkmalsnummer = <c>-inspectioncharacteristic.
      ls_row-kurztext       = <c>-inspectioncharacteristictext.
      ls_row-pruefmethode   = <c>-inspectionmethodtext.
      ls_row-langtext       = _get_longtext(
        iv_prueflos = <c>-inspectionlot
        iv_vorglfnr = <c>-insplanoperationinternalid
        iv_merknr   = <c>-inspectioncharacteristic ).
      ls_row-losgroesse     = |{ <c>-inspcharacteristicsamplesize }|.
      IF ls_row-stammerkmal(2) = `RQ`.
        ls_row-qc_department = `X`.
      ENDIF.
      DATA(lt_radii) = _get_radii_codes(
        iv_prueflos = <c>-inspectionlot
        iv_vorglfnr = <c>-insplanoperationinternalid
        iv_merknr   = <c>-inspectioncharacteristic ).
      DATA lv_radii_cnt TYPE i.
      lv_radii_cnt = 0.
      LOOP AT lt_radii INTO DATA(lv_rc).
        lv_radii_cnt += 1.
        IF lv_radii_cnt <= 25.
          IF ls_row-radii_codes_1 IS NOT INITIAL. ls_row-radii_codes_1 &&= `,`. ENDIF.
          ls_row-radii_codes_1 &&= lv_rc.
        ELSE.
          IF ls_row-radii_codes_2 IS NOT INITIAL. ls_row-radii_codes_2 &&= `,`. ENDIF.
          ls_row-radii_codes_2 &&= lv_rc.
        ENDIF.
      ENDLOOP.
      IF <c>-inspspecisquantitative = `X`.
        ls_row-is_quantitative = abap_true.
        ls_row-sollwert_qn     = |{ <c>-inspspectargetvalue }|.
        ls_row-toleranz_ob     = |{ <c>-inspspecupperlimit }|.
        ls_row-toleranz_un     = |{ <c>-inspspeclowerlimit }|.
      ELSE.
        ls_row-is_quantitative = abap_false.
        ls_row-sollwert_ql     = <c>-selectedcodeset.
        ls_row-toleranz_ql     = <c>-characteristicattributecatalog.
        ls_row-codes = _get_codes(
          iv_prueflos = <c>-inspectionlot
          iv_vorglfnr = <c>-insplanoperationinternalid
          iv_merknr   = <c>-inspectioncharacteristic ).
      ENDIF.
      INSERT ls_row INTO TABLE rt_data.
    ENDLOOP.
  ENDMETHOD.


  METHOD _esc.
    rv_val = iv_val.
    REPLACE ALL OCCURRENCES OF `&` IN rv_val WITH `&amp;`.
    REPLACE ALL OCCURRENCES OF `<` IN rv_val WITH `&lt;`.
    REPLACE ALL OCCURRENCES OF `>` IN rv_val WITH `&gt;`.
    REPLACE ALL OCCURRENCES OF `"` IN rv_val WITH `&quot;`.
  ENDMETHOD.


  METHOD _cell.
    CONSTANTS lc_alpha TYPE c LENGTH 26 VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    DATA(lv_q) = ( iv_col - 1 ) DIV 26.
    DATA(lv_r) = ( iv_col - 1 ) MOD 26.
    DATA(lv_col_str) = CONV string( lc_alpha+lv_r(1) ).
    IF lv_q > 0.
      DATA(lv_q1) = lv_q - 1.
      lv_col_str = lc_alpha+lv_q1(1) && lv_col_str.
    ENDIF.
    rv_xml = |<c r="{ lv_col_str }{ iv_row }" t="inlineStr"><is><t>{ _esc( iv_val ) }</t></is></c>|.
  ENDMETHOD.


  METHOD _send_xlsx.
    " Max-Codes über alle QL-Merkmale bestimmen
    DATA(lv_max_codes) = 1.
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<r>).
      IF <r>-is_quantitative = abap_false AND lines( <r>-codes ) > lv_max_codes.
        lv_max_codes = lines( <r>-codes ).
      ENDIF.
    ENDLOOP.

    " Header-Zeile (Zeile 1) — fixe Spalten 1-27
    DATA(lv_hdr) =
        _cell( iv_col = 1  iv_row = 1 iv_val = |{ TEXT-001 }| )
     && _cell( iv_col = 2  iv_row = 1 iv_val = |{ TEXT-002 }| )
     && _cell( iv_col = 3  iv_row = 1 iv_val = |{ TEXT-003 }| )
     && _cell( iv_col = 4  iv_row = 1 iv_val = |{ TEXT-004 }| )
     && _cell( iv_col = 5  iv_row = 1 iv_val = |{ TEXT-005 }| )
     && _cell( iv_col = 6  iv_row = 1 iv_val = |{ TEXT-006 }| )
     && _cell( iv_col = 7  iv_row = 1 iv_val = |{ TEXT-007 }| )
     && _cell( iv_col = 8  iv_row = 1 iv_val = |{ TEXT-008 }| )
     && _cell( iv_col = 9  iv_row = 1 iv_val = |{ TEXT-009 }| )
     && _cell( iv_col = 10 iv_row = 1 iv_val = |{ TEXT-010 }| )
     && _cell( iv_col = 11 iv_row = 1 iv_val = |{ TEXT-011 }| )
     && _cell( iv_col = 12 iv_row = 1 iv_val = |{ TEXT-012 }| )
     && _cell( iv_col = 13 iv_row = 1 iv_val = |{ TEXT-013 }| )
     && _cell( iv_col = 14 iv_row = 1 iv_val = |{ TEXT-014 }| )
     && _cell( iv_col = 15 iv_row = 1 iv_val = |{ TEXT-015 }| )
     && _cell( iv_col = 16 iv_row = 1 iv_val = |{ TEXT-016 }| )
     && _cell( iv_col = 17 iv_row = 1 iv_val = |{ TEXT-017 }| )
     && _cell( iv_col = 18 iv_row = 1 iv_val = |{ TEXT-018 }| )
     && _cell( iv_col = 19 iv_row = 1 iv_val = |{ TEXT-019 }| )
     && _cell( iv_col = 20 iv_row = 1 iv_val = |{ TEXT-020 }| )
     && _cell( iv_col = 21 iv_row = 1 iv_val = |{ TEXT-021 }| )
     && _cell( iv_col = 22 iv_row = 1 iv_val = |{ TEXT-022 }| )
     && _cell( iv_col = 23 iv_row = 1 iv_val = |{ TEXT-023 }| )
     && _cell( iv_col = 24 iv_row = 1 iv_val = |{ TEXT-024 }| )
     && _cell( iv_col = 25 iv_row = 1 iv_val = |{ TEXT-025 }| )
     && _cell( iv_col = 26 iv_row = 1 iv_val = |{ TEXT-026 }| )
     && _cell( iv_col = 27 iv_row = 1 iv_val = |{ TEXT-029 }| )
     && _cell( iv_col = 28 iv_row = 1 iv_val = |{ TEXT-030 }| )
     && _cell( iv_col = 29 iv_row = 1 iv_val = |{ TEXT-027 }| ).
    DATA(lv_col_idx) = 30.
    DO lv_max_codes - 1 TIMES.
      lv_hdr &&= _cell( iv_col = lv_col_idx iv_row = 1 iv_val = |Code { lv_col_idx - 28 }| ).
      lv_col_idx += 1.
    ENDDO.
    DATA(lv_rows) = |<row r="1">{ lv_hdr }</row>|.

    " Datenzeilen
    DATA(lv_ridx) = 1.
    DATA lv_cells TYPE string.
    DATA lv_cc    TYPE i.
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<d>).
      lv_ridx += 1.
      lv_cells =
           _cell( iv_col = 1  iv_row = lv_ridx iv_val = |{ <d>-prueflosnummer }| )
        && _cell( iv_col = 2  iv_row = lv_ridx iv_val = |{ <d>-plangruppe }|     )
        && _cell( iv_col = 3  iv_row = lv_ridx iv_val = |{ <d>-pgz }|            )
        && _cell( iv_col = 4  iv_row = lv_ridx iv_val = |{ <d>-pgz_text }|       )
        && _cell( iv_col = 5  iv_row = lv_ridx iv_val = |{ <d>-lieferant_nr }|   )
        && _cell( iv_col = 6  iv_row = lv_ridx iv_val = |{ <d>-bestell_nr }|     )
        && _cell( iv_col = 7  iv_row = lv_ridx iv_val = |{ <d>-bestell_pos }|    )
        && _cell( iv_col = 8  iv_row = lv_ridx iv_val = |{ <d>-material }|       )
        && _cell( iv_col = 9  iv_row = lv_ridx iv_val = |{ <d>-mstae_text }|     )
        && _cell( iv_col = 10 iv_row = lv_ridx iv_val = |{ <d>-vorgangsnummer }| )
        && _cell( iv_col = 11 iv_row = lv_ridx iv_val = |{ <d>-vorgang_text }|   )
        && _cell( iv_col = 12 iv_row = lv_ridx iv_val = |{ <d>-fhm }|            )
        && _cell( iv_col = 13 iv_row = lv_ridx iv_val = |{ <d>-fhm_text }|       )
        && _cell( iv_col = 14 iv_row = lv_ridx iv_val = |{ <d>-stammerkmal }|    )
        && _cell( iv_col = 15 iv_row = lv_ridx iv_val = |{ <d>-quanqual }|       )
        && _cell( iv_col = 16 iv_row = lv_ridx iv_val = |{ <d>-merkmalsnummer }| )
        && _cell( iv_col = 17 iv_row = lv_ridx iv_val = |{ <d>-kurztext }|       )
        && _cell( iv_col = 18 iv_row = lv_ridx iv_val = |{ <d>-pruefmethode }|   )
        && _cell( iv_col = 19 iv_row = lv_ridx iv_val = |{ <d>-sollwert_ql }|    )
        && _cell( iv_col = 20 iv_row = lv_ridx iv_val = |{ <d>-toleranz_ql }|    )
        && _cell( iv_col = 21 iv_row = lv_ridx iv_val = |{ <d>-langtext }|       )
        && _cell( iv_col = 22 iv_row = lv_ridx iv_val = |{ <d>-sollwert_qn }|    )
        && _cell( iv_col = 23 iv_row = lv_ridx iv_val = |{ <d>-toleranz_ob }|    )
        && _cell( iv_col = 24 iv_row = lv_ridx iv_val = |{ <d>-toleranz_un }|    )
        && _cell( iv_col = 25 iv_row = lv_ridx iv_val = |{ <d>-losgroesse }|     )
        && _cell( iv_col = 26 iv_row = lv_ridx iv_val = |{ <d>-qc_department }|  )
        && _cell( iv_col = 27 iv_row = lv_ridx iv_val = `` )
        && _cell( iv_col = 28 iv_row = lv_ridx iv_val = `` ).
      IF <d>-is_quantitative = abap_true.
        lv_cells &&= _cell( iv_col = 29 iv_row = lv_ridx iv_val = `` ).
      ELSE.
        lv_cc = 29.
        LOOP AT <d>-codes ASSIGNING FIELD-SYMBOL(<cd>).
          lv_cells &&= _cell( iv_col = lv_cc iv_row = lv_ridx iv_val = condense( <cd>-kurztext ) ).
          lv_cc += 1.
        ENDLOOP.
      ENDIF.
      lv_rows &&= |<row r="{ lv_ridx }">{ lv_cells }</row>|.
    ENDLOOP.

    " <cols>-Block: fixe Spalten 1-26, dynamisch ab 27
    DATA(lv_cols) =
        `<col min="1"  max="1"  width="22" customWidth="1"/>` &&
        `<col min="2"  max="2"  width="12" customWidth="1"/>` &&
        `<col min="3"  max="3"  width="6"  customWidth="1"/>` &&
        `<col min="4"  max="4"  width="36" customWidth="1"/>` &&
        `<col min="5"  max="5"  width="14" customWidth="1"/>` &&
        `<col min="6"  max="6"  width="14" customWidth="1"/>` &&
        `<col min="7"  max="7"  width="12" customWidth="1"/>` &&
        `<col min="8"  max="8"  width="22" customWidth="1"/>` &&
        `<col min="9"  max="9"  width="32" customWidth="1"/>` &&
        `<col min="10" max="10" width="10" customWidth="1"/>` &&
        `<col min="11" max="11" width="36" customWidth="1"/>` &&
        `<col min="12" max="12" width="12" customWidth="1"/>` &&
        `<col min="13" max="13" width="36" customWidth="1"/>` &&
        `<col min="14" max="14" width="14" customWidth="1"/>` &&
        `<col min="15" max="15" width="8"  customWidth="1"/>` &&
        `<col min="16" max="16" width="10" customWidth="1"/>` &&
        `<col min="17" max="17" width="36" customWidth="1"/>` &&
        `<col min="18" max="18" width="36" customWidth="1"/>` &&
        `<col min="19" max="19" width="20" customWidth="1"/>` &&
        `<col min="20" max="20" width="10" customWidth="1"/>` &&
        `<col min="21" max="21" width="60" customWidth="1"/>` &&
        `<col min="22" max="22" width="18" customWidth="1"/>` &&
        `<col min="23" max="23" width="18" customWidth="1"/>` &&
        `<col min="24" max="24" width="18" customWidth="1"/>` &&
        `<col min="25" max="25" width="12" customWidth="1"/>` &&
        `<col min="26" max="26" width="14" customWidth="1"/>` &&
        `<col min="27" max="27" width="18" customWidth="1"/>` &&
        `<col min="28" max="28" width="18" customWidth="1"/>`.
    DATA(lv_dyn_col) = 29.
    DO lv_max_codes TIMES.
      lv_cols &&= |<col min="{ lv_dyn_col }" max="{ lv_dyn_col }" width="18" customWidth="1"/>|.
      lv_dyn_col += 1.
    ENDDO.

    DATA lv_dv_entries TYPE string.
    DATA lv_dv_count   TYPE i.
    DATA lv_dv_ridx    TYPE i VALUE 1.
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<dv>).
      lv_dv_ridx += 1.
      IF <dv>-radii_codes_1 IS NOT INITIAL.
        lv_dv_entries &&=
          |<dataValidation type="list" allowBlank="1" showDropDown="0" sqref="AA{ lv_dv_ridx }">| &&
          |<formula1>&quot;{ _esc( <dv>-radii_codes_1 ) }&quot;</formula1>| &&
          `</dataValidation>`.
        lv_dv_count += 1.
      ENDIF.
      IF <dv>-radii_codes_2 IS NOT INITIAL.
        lv_dv_entries &&=
          |<dataValidation type="list" allowBlank="1" showDropDown="0" sqref="AB{ lv_dv_ridx }">| &&
          |<formula1>&quot;{ _esc( <dv>-radii_codes_2 ) }&quot;</formula1>| &&
          `</dataValidation>`.
        lv_dv_count += 1.
      ENDIF.
    ENDLOOP.
    DATA lv_dv TYPE string.
    IF lv_dv_count > 0.
      lv_dv = |<dataValidations count="{ lv_dv_count }">{ lv_dv_entries }</dataValidations>|.
    ENDIF.

    DATA(lv_sheet) =
        `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` &&
        `<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">` &&
        `<cols>` && lv_cols && `</cols>` &&
        `<sheetData>` && lv_rows && `</sheetData>` &&
        lv_dv &&
        `</worksheet>`.

    DATA(lv_wb) =
        `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` &&
        `<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"` &&
        ` xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">` &&
        `<sheets><sheet name="Daten" sheetId="1" r:id="rId1"/></sheets>` &&
        `</workbook>`.

    DATA(lv_ct) =
        `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` &&
        `<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">` &&
        `<Default Extension="rels"` &&
        ` ContentType="application/vnd.openxmlformats-package.relationships+xml"/>` &&
        `<Default Extension="xml"  ContentType="application/xml"/>` &&
        `<Override PartName="/xl/workbook.xml"` &&
        ` ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>` &&
        `<Override PartName="/xl/worksheets/sheet1.xml"` &&
        ` ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>` &&
        `</Types>`.

    DATA(lv_rels) =
        `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` &&
        `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` &&
        `<Relationship Id="rId1"` &&
        ` Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"` &&
        ` Target="xl/workbook.xml"/>` &&
        `</Relationships>`.

    DATA(lv_wb_rels) =
        `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` &&
        `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` &&
        `<Relationship Id="rId1"` &&
        ` Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"` &&
        ` Target="worksheets/sheet1.xml"/>` &&
        `</Relationships>`.

    DATA(lo_zip) = NEW cl_abap_zip( ).
    lo_zip->add( name    = `[Content_Types].xml`
                 content = cl_abap_codepage=>convert_to( source = lv_ct      codepage = `UTF-8` ) ).
    lo_zip->add( name    = `_rels/.rels`
                 content = cl_abap_codepage=>convert_to( source = lv_rels    codepage = `UTF-8` ) ).
    lo_zip->add( name    = `xl/workbook.xml`
                 content = cl_abap_codepage=>convert_to( source = lv_wb      codepage = `UTF-8` ) ).
    lo_zip->add( name    = `xl/_rels/workbook.xml.rels`
                 content = cl_abap_codepage=>convert_to( source = lv_wb_rels codepage = `UTF-8` ) ).
    lo_zip->add( name    = `xl/worksheets/sheet1.xml`
                 content = cl_abap_codepage=>convert_to( source = lv_sheet   codepage = `UTF-8` ) ).

    DATA(lv_content) = lo_zip->save( ).
    server->response->set_header_field(
      name  = `Content-Disposition`
      value = |attachment; filename="{ iv_name }"| ).
    server->response->set_header_field(
      name  = `Content-Type`
      value = `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` ).
    server->response->set_data( lv_content ).
    server->response->set_status( code = 200 reason = `OK` ).
  ENDMETHOD.

ENDCLASS.

