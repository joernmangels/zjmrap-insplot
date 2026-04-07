CLASS zjmqmi_cl_icf_download DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

  PRIVATE SECTION.
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
             sollwert_qn     TYPE c LENGTH 20,
             toleranz_ob     TYPE c LENGTH 20,
             toleranz_un     TYPE c LENGTH 20,
             sollwert_ql     TYPE c LENGTH 8,
             toleranz_ql     TYPE c LENGTH 4,
             losgroesse      TYPE c LENGTH 10,
             pruefergebnis   TYPE c LENGTH 20,
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

    METHODS _get_lot_header
      IMPORTING lv_lot        TYPE qals-prueflos
      RETURNING VALUE(rs_hdr) TYPE ty_lot_header.

    METHODS _fill_data
      IMPORTING ls_hdr  TYPE ty_lot_header
      CHANGING  lt_data TYPE ty_data.

    METHODS _send_xlsx
      IMPORTING
        server  TYPE REF TO if_http_server
        lt_data TYPE ty_data
        lv_name TYPE string.

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

    DATA lt_data TYPE ty_data.
    DATA(lv_lot_str) = server->request->get_form_field( 'lot' ).

    APPEND VALUE ty_row(
      prueflosnummer = 'Prueflosnummer'
      plangruppe     = 'Plangruppe'
      pgz            = 'PGZ'
      pgz_text       = 'PGZ-Text'
      lieferant_nr   = 'Lieferant-Nr'
      bestell_nr     = 'Bestell-Nr'
      bestell_pos    = 'Bestell-Pos'
      material       = 'Material'
      mstae_text     = 'Mat.-Status'
      vorgangsnummer = 'Vorgang'
      vorgang_text   = 'Vorgangs-Beschreibung'
      fhm            = 'FHM'
      fhm_text       = 'FHM-Beschreibung'
      stammerkmal    = 'Stammmerkmal'
      quanqual       = 'QN/QL'
      merkmalsnummer = 'Merkmal'
      kurztext       = 'Kurztext'
      sollwert_qn    = 'Sollwert QN'
      toleranz_ob    = 'Toleranz oben'
      toleranz_un    = 'Toleranz unten'
      sollwert_ql    = 'Soll-QL'
      toleranz_ql    = 'Katalog QL'
      losgroesse     = 'Losgröße'
      pruefergebnis  = 'Bewertung'
    ) TO lt_data.

    IF lv_lot_str IS NOT INITIAL.
      DATA(lv_lot) = CONV qals-prueflos( lv_lot_str ).
      DATA(ls_hdr) = _get_lot_header( lv_lot ).
      _fill_data( EXPORTING ls_hdr = ls_hdr CHANGING lt_data = lt_data ).

      GET TIME STAMP FIELD DATA(lv_ts_single).
      MODIFY zjmqmit_status FROM @( VALUE #(
        prueflos   = lv_lot
        last_dl_at = lv_ts_single
        last_dl_by = sy-uname ) ).
      COMMIT WORK.

      _send_xlsx( server  = server
                  lt_data = lt_data
                  lv_name = |{ condense( lv_lot_str ) }.xlsx| ).
      RETURN.
    ENDIF.

    SELECT prueflos FROM zjmqmit_dl_token
      WHERE created_by = @sy-uname
      ORDER BY prueflos
      INTO TABLE @DATA(lt_lots).

    IF lt_lots IS INITIAL.
      server->response->set_status( code = 404 reason = 'Keine Prueflose vorgemerkt' ).
      RETURN.
    ENDIF.

    GET TIME STAMP FIELD DATA(lv_ts_batch).
    LOOP AT lt_lots ASSIGNING FIELD-SYMBOL(<lot>).
      DATA(ls_hdr2) = _get_lot_header( <lot>-prueflos ).
      _fill_data( EXPORTING ls_hdr = ls_hdr2 CHANGING lt_data = lt_data ).
      MODIFY zjmqmit_status FROM @( VALUE #(
        prueflos   = <lot>-prueflos
        last_dl_at = lv_ts_batch
        last_dl_by = sy-uname ) ).
    ENDLOOP.

    DELETE FROM zjmqmit_dl_token WHERE created_by = @sy-uname.
    COMMIT WORK.

    _send_xlsx( server  = server
                lt_data = lt_data
                lv_name = |Vormerkliste_{ sy-uname }.xlsx| ).

  ENDMETHOD.

  METHOD _get_lot_header.
    SELECT SINGLE
        InspectionLot, BillOfOperationsGroup, BillOfOperationsVariant,
        BillOfOperationsType, Supplier, PurchasingDocument,
        PurchasingDocumentItem, Material
      FROM I_InspectionLot
      WHERE InspectionLot = @lv_lot
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

  METHOD _fill_data.
    DATA lv_pgz_text TYPE c LENGTH 40.
    SELECT SINGLE ktext FROM plko
      WHERE plnty = @ls_hdr-billofoperationstype
        AND plnnr = @ls_hdr-billofoperationsgroup
        AND plnal = @ls_hdr-billofoperationsvariant
      INTO @lv_pgz_text.

    DATA lv_mstae TYPE mmsta.
    SELECT SINGLE mstae FROM mara
      WHERE matnr = @ls_hdr-material
      INTO @lv_mstae.
    DATA lv_mstae_text TYPE c LENGTH 40.
    IF lv_mstae IS NOT INITIAL.
      SELECT SINGLE mtstb FROM t141t
        WHERE spras = @sy-langu AND mmsta = @lv_mstae
        INTO @lv_mstae_text.
    ENDIF.

    DATA lt_char TYPE ty_chars.
    SELECT ic~InspectionLot              AS inspectionlot,
           ic~InspPlanOperationInternalID AS insplanoperationinternalid,
           ic~InspectionCharacteristic    AS inspectioncharacteristic,
           ic~InspectionOperation         AS inspectionoperation,
           ic~OperationText               AS operationtext,
           ic~InspectionCharacteristicText AS inspectioncharacteristictext,
           ic~InspectionMethod            AS inspectionmethod,
           ic~InspectionMethodVersion     AS inspectionmethodversion,
           ic~InspectionMethodPlant       AS inspectionmethodplant,
           ic~InspectionSpecification     AS inspectionspecification,
           ic~SelectedCodeSet             AS selectedcodeset,
           ic~CharacteristicAttributeCatalog AS characteristicattributecatalog,
           ic~InspCharacteristicSampleSize AS inspcharacteristicsamplesize,
           ic~InspSpecIsQuantitative      AS inspspecisquantitative,
           ic~InspSpecTargetValue         AS inspspectargetvalue,
           ic~InspSpecUpperLimit          AS inspspecupperlimit,
           ic~InspSpecLowerLimit          AS inspspeclowerlimit
      FROM zjmqmi_i_insplot_char AS ic
      WHERE ic~InspectionLot = @ls_hdr-inspectionlot
      ORDER BY ic~InspectionOperation, ic~InspectionCharacteristic
      INTO CORRESPONDING FIELDS OF TABLE @lt_char.

    LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<c>).
      DATA lv_fhm_text TYPE c LENGTH 40.
      IF <c>-inspectionmethod IS NOT INITIAL.
        SELECT SINGLE InspectionMethodText
          FROM I_InspectionMethodVersionText
          WHERE InspectionMethodPlant   = @<c>-inspectionmethodplant
            AND InspectionMethod        = @<c>-inspectionmethod
            AND InspectionMethodVersion = @<c>-inspectionmethodversion
            AND Language                = @sy-langu
          INTO @lv_fhm_text.
      ELSE.
        CLEAR lv_fhm_text.
      ENDIF.

      APPEND VALUE ty_row(
        prueflosnummer = <c>-inspectionlot
        plangruppe     = ls_hdr-billofoperationsgroup
        pgz            = ls_hdr-billofoperationsvariant
        pgz_text       = lv_pgz_text
        lieferant_nr   = ls_hdr-supplier
        bestell_nr     = ls_hdr-purchasingdocument
        bestell_pos    = ls_hdr-purchasingdocumentitem
        material       = ls_hdr-material
        mstae_text     = lv_mstae_text
        vorgangsnummer = <c>-inspectionoperation
        vorgang_text   = <c>-operationtext
        fhm            = <c>-inspectionmethod
        fhm_text       = lv_fhm_text
        stammerkmal    = <c>-inspectionspecification
        quanqual       = COND #( WHEN <c>-inspspecisquantitative = 'X' THEN 'QN' ELSE 'QL' )
        merkmalsnummer = <c>-inspectioncharacteristic
        kurztext       = <c>-inspectioncharacteristictext
        sollwert_qn    = COND #( WHEN <c>-inspspecisquantitative = 'X'
                                 THEN |{ <c>-inspspectargetvalue }| ELSE '' )
        toleranz_ob    = COND #( WHEN <c>-inspspecisquantitative = 'X'
                                 THEN |{ <c>-inspspecupperlimit }| ELSE '' )
        toleranz_un    = COND #( WHEN <c>-inspspecisquantitative = 'X'
                                 THEN |{ <c>-inspspeclowerlimit }| ELSE '' )
        sollwert_ql    = COND #( WHEN <c>-inspspecisquantitative <> 'X'
                                 THEN <c>-selectedcodeset ELSE '' )
        toleranz_ql    = COND #( WHEN <c>-inspspecisquantitative <> 'X'
                                 THEN <c>-characteristicattributecatalog ELSE '' )
        losgroesse     = |{ <c>-inspcharacteristicsamplesize }|
        pruefergebnis  = 'unbewertet'
      ) TO lt_data.
    ENDLOOP.
  ENDMETHOD.

  METHOD _esc.
    rv_val = iv_val.
    REPLACE ALL OCCURRENCES OF '&'  IN rv_val WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<'  IN rv_val WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>'  IN rv_val WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"'  IN rv_val WITH '&quot;'.
  ENDMETHOD.

  METHOD _cell.
    DATA(lc_alpha) = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    DATA lv_off    TYPE i.
    DATA lv_letter TYPE c LENGTH 1.
    lv_off    = iv_col - 1.
    lv_letter = lc_alpha+lv_off(1).
    rv_xml = |<c r="{ lv_letter }{ iv_row }" t="inlineStr"><is><t>{ _esc( iv_val ) }</t></is></c>|.
  ENDMETHOD.

  METHOD _send_xlsx.
    DATA lv_rows TYPE string.
    DATA lv_ridx TYPE i VALUE 0.

    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<r>).
      lv_ridx = lv_ridx + 1.
      DATA(lv_cells) = _cell( iv_col = 1  iv_row = lv_ridx iv_val = |{ <r>-prueflosnummer }| )
                    && _cell( iv_col = 2  iv_row = lv_ridx iv_val = |{ <r>-plangruppe }|     )
                    && _cell( iv_col = 3  iv_row = lv_ridx iv_val = |{ <r>-pgz }|            )
                    && _cell( iv_col = 4  iv_row = lv_ridx iv_val = |{ <r>-pgz_text }|       )
                    && _cell( iv_col = 5  iv_row = lv_ridx iv_val = |{ <r>-lieferant_nr }|   )
                    && _cell( iv_col = 6  iv_row = lv_ridx iv_val = |{ <r>-bestell_nr }|     )
                    && _cell( iv_col = 7  iv_row = lv_ridx iv_val = |{ <r>-bestell_pos }|    )
                    && _cell( iv_col = 8  iv_row = lv_ridx iv_val = |{ <r>-material }|       )
                    && _cell( iv_col = 9  iv_row = lv_ridx iv_val = |{ <r>-mstae_text }|     )
                    && _cell( iv_col = 10 iv_row = lv_ridx iv_val = |{ <r>-vorgangsnummer }| )
                    && _cell( iv_col = 11 iv_row = lv_ridx iv_val = |{ <r>-vorgang_text }|   )
                    && _cell( iv_col = 12 iv_row = lv_ridx iv_val = |{ <r>-fhm }|            )
                    && _cell( iv_col = 13 iv_row = lv_ridx iv_val = |{ <r>-fhm_text }|       )
                    && _cell( iv_col = 14 iv_row = lv_ridx iv_val = |{ <r>-stammerkmal }|    )
                    && _cell( iv_col = 15 iv_row = lv_ridx iv_val = |{ <r>-quanqual }|       )
                    && _cell( iv_col = 16 iv_row = lv_ridx iv_val = |{ <r>-merkmalsnummer }| )
                    && _cell( iv_col = 17 iv_row = lv_ridx iv_val = |{ <r>-kurztext }|       )
                    && _cell( iv_col = 18 iv_row = lv_ridx iv_val = |{ <r>-sollwert_qn }|    )
                    && _cell( iv_col = 19 iv_row = lv_ridx iv_val = |{ <r>-toleranz_ob }|    )
                    && _cell( iv_col = 20 iv_row = lv_ridx iv_val = |{ <r>-toleranz_un }|    )
                    && _cell( iv_col = 21 iv_row = lv_ridx iv_val = |{ <r>-sollwert_ql }|    )
                    && _cell( iv_col = 22 iv_row = lv_ridx iv_val = |{ <r>-toleranz_ql }|    )
                    && _cell( iv_col = 23 iv_row = lv_ridx iv_val = |{ <r>-losgroesse }|     )
                    && _cell( iv_col = 24 iv_row = lv_ridx iv_val = |{ <r>-pruefergebnis }|  ).
      lv_rows = lv_rows && |<row r="{ lv_ridx }">{ lv_cells }</row>|.
    ENDLOOP.

    DATA(lv_sheet) =
        `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` &&
        `<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">` &&
        `<cols>` &&
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
        `<col min="18" max="18" width="18" customWidth="1"/>` &&
        `<col min="19" max="19" width="18" customWidth="1"/>` &&
        `<col min="20" max="20" width="18" customWidth="1"/>` &&
        `<col min="21" max="21" width="14" customWidth="1"/>` &&
        `<col min="22" max="22" width="12" customWidth="1"/>` &&
        `<col min="23" max="23" width="12" customWidth="1"/>` &&
        `<col min="24" max="24" width="22" customWidth="1"/>` &&
        `</cols>` &&
        `<sheetData>` && lv_rows && `</sheetData>` &&
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
        `<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>` &&
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

    DATA lo_zip TYPE REF TO cl_abap_zip.
    CREATE OBJECT lo_zip.
    lo_zip->add( name    = '[Content_Types].xml'
                 content = cl_abap_codepage=>convert_to( source = lv_ct   codepage = 'UTF-8' ) ).
    lo_zip->add( name    = '_rels/.rels'
                 content = cl_abap_codepage=>convert_to( source = lv_rels codepage = 'UTF-8' ) ).
    lo_zip->add( name    = 'xl/workbook.xml'
                 content = cl_abap_codepage=>convert_to( source = lv_wb   codepage = 'UTF-8' ) ).
    lo_zip->add( name    = 'xl/_rels/workbook.xml.rels'
                 content = cl_abap_codepage=>convert_to( source = lv_wb_rels codepage = 'UTF-8' ) ).
    lo_zip->add( name    = 'xl/worksheets/sheet1.xml'
                 content = cl_abap_codepage=>convert_to( source = lv_sheet codepage = 'UTF-8' ) ).

    DATA(lv_content) = lo_zip->save( ).

    server->response->set_header_field(
      name  = 'Content-Disposition'
      value = |attachment; filename="{ lv_name }"| ).
    server->response->set_header_field(
      name  = 'Content-Type'
      value = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ).
    server->response->set_data( lv_content ).
    server->response->set_status( code = 200 reason = 'OK' ).
  ENDMETHOD.

ENDCLASS.
