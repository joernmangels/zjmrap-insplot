CLASS zjmqmi_cl_upload_helper DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_filter_lots TYPE STANDARD TABLE OF qals-prueflos WITH EMPTY KEY.
    METHODS process_upload
      IMPORTING iv_filename    TYPE string
                iv_xstring     TYPE xstring
                it_filter_lots TYPE ty_filter_lots OPTIONAL
                iv_overwrite   TYPE abap_bool      OPTIONAL
      RETURNING VALUE(rv_msg)  TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_upload_row,
             prueflosnummer TYPE c LENGTH 18,
             vorgangsnummer TYPE c LENGTH 4,
             quanqual       TYPE c LENGTH 2,
             merkmalsnummer TYPE c LENGTH 4,
             messwert       TYPE string,
             code_col_idx   TYPE i,
             excel_row      TYPE i,
             radii_1        TYPE string,
             radii_2        TYPE string,
           END OF ty_upload_row.
    TYPES ty_upload_rows TYPE STANDARD TABLE OF ty_upload_row WITH EMPTY KEY.
    TYPES: BEGIN OF ty_up_code,
             code       TYPE qpac-code,
             codegruppe TYPE qpac-codegruppe,
             bewertung  TYPE qpac-bewertung,
             kurztext   TYPE qpct-kurztext,
           END OF ty_up_code.
    TYPES ty_up_codes TYPE STANDARD TABLE OF ty_up_code WITH EMPTY KEY.
    TYPES: BEGIN OF ty_prot_entry,
             prueflos  TYPE qals-prueflos,
             filename  TYPE string,
             excel_row TYPE i,
             inspoper  TYPE string,
             merknr    TYPE string,
             status    TYPE c LENGTH 1,
             msg       TYPE string,
           END OF ty_prot_entry.
    TYPES: BEGIN OF ty_bapi_input,
             char_results   TYPE TABLE OF bapi2045d2 WITH EMPTY KEY,
             sample_results TYPE TABLE OF bapi2045d3 WITH EMPTY KEY,
             single_results TYPE TABLE OF bapi2045d4 WITH EMPTY KEY,
           END OF ty_bapi_input.
    TYPES ty_return_tab TYPE TABLE OF bapiret2 WITH EMPTY KEY.
    TYPES ty_ul_status  TYPE c LENGTH 1.

    METHODS _col_letter_to_idx
      IMPORTING iv_col        TYPE string
      RETURNING VALUE(rv_idx) TYPE i.

    METHODS _parse_xlsx
      IMPORTING iv_xstring     TYPE xstring
      RETURNING VALUE(rt_rows) TYPE ty_upload_rows.

    METHODS _get_codes_for_char
      IMPORTING iv_prueflos     TYPE qals-prueflos
                iv_vornr        TYPE string
                iv_merknr       TYPE string
      RETURNING VALUE(rt_codes) TYPE ty_up_codes.

    METHODS _get_qamv_steuerkz
      IMPORTING iv_prueflos        TYPE qals-prueflos
                iv_vornr           TYPE string
                iv_merknr          TYPE string
      RETURNING VALUE(rv_steuerkz) TYPE qamv-steuerkz.

    METHODS _get_evaluation
      IMPORTING iv_prueflos      TYPE qals-prueflos
                iv_vornr         TYPE string
                iv_merknr        TYPE string
                iv_messwert      TYPE string
      RETURNING VALUE(rv_result) TYPE char1.

    METHODS _get_next_res_no
      IMPORTING iv_prueflos    TYPE qals-prueflos
                iv_inspoper    TYPE vornr
                iv_inspchar    TYPE qamv-merknr
      RETURNING VALUE(rv_next) TYPE numc4.

    METHODS _get_radii_code
      IMPORTING iv_prueflos    TYPE qals-prueflos
                iv_vornr       TYPE string
                iv_merknr      TYPE string
                iv_kurztext    TYPE string
      RETURNING VALUE(rs_code) TYPE ty_up_code.

    METHODS _invalidate_char
      IMPORTING iv_prueflos TYPE qals-prueflos
                iv_inspoper TYPE vornr
                iv_inspchar TYPE qamv-merknr.

    METHODS _write_prot
      IMPORTING entry TYPE ty_prot_entry.

    METHODS _update_status
      IMPORTING iv_prueflos TYPE qals-prueflos
                iv_status   TYPE c.

    METHODS _collect_operations
      IMPORTING it_rows       TYPE ty_upload_rows
      RETURNING VALUE(rt_ops) TYPE string_table.

    METHODS _build_bapi_input
      IMPORTING iv_prueflos    TYPE qals-prueflos
                iv_vornr       TYPE string
                iv_filename    TYPE string
                it_rows        TYPE ty_upload_rows
                iv_overwrite   TYPE abap_bool OPTIONAL
      RETURNING VALUE(rs_input) TYPE ty_bapi_input.

    METHODS _write_prot_for_operation
      IMPORTING iv_prueflos  TYPE qals-prueflos
                iv_filename  TYPE string
                it_rows      TYPE ty_upload_rows
                iv_vornr     TYPE string
                it_return    TYPE ty_return_tab
      CHANGING  cv_ul_status TYPE ty_ul_status.

    METHODS _build_success_prot_msg
      IMPORTING iv_prueflos    TYPE qals-prueflos
                iv_vornr       TYPE string
                is_row         TYPE ty_upload_row
      RETURNING VALUE(rv_msg)  TYPE string.

    METHODS _post_results
      IMPORTING iv_prueflos  TYPE qals-prueflos
                iv_filename  TYPE string
                it_rows      TYPE ty_upload_rows
                iv_overwrite TYPE abap_bool OPTIONAL.
ENDCLASS.

CLASS zjmqmi_cl_upload_helper IMPLEMENTATION.

  METHOD process_upload.
    DATA(lt_rows) = _parse_xlsx( iv_xstring ).
    IF lt_rows IS INITIAL.
      rv_msg = TEXT-001.
      RETURN.
    ENDIF.

    DATA lt_lots TYPE TABLE OF qals-prueflos WITH EMPTY KEY.
    LOOP AT lt_rows INTO DATA(ls_r).
      INSERT CONV qals-prueflos( condense( ls_r-prueflosnummer ) ) INTO TABLE lt_lots.
    ENDLOOP.
    SORT lt_lots BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_lots COMPARING table_line.

    IF it_filter_lots IS NOT INITIAL.
      DELETE lt_lots WHERE NOT table_line IN
        VALUE rseloption( FOR lv IN it_filter_lots
                          ( sign = 'I' option = 'EQ' low = lv ) ).
    ENDIF.

    IF lt_lots IS INITIAL.
      rv_msg = TEXT-002.
      RETURN.
    ENDIF.

    DATA lv_detail TYPE string.
    DATA lv_total  TYPE i.
    LOOP AT lt_lots INTO DATA(lv_lot).
      DATA(lt_lot_rows) = VALUE ty_upload_rows(
        FOR r IN lt_rows WHERE ( prueflosnummer = lv_lot ) ( r )
      ).
      DATA(lv_lot_cnt) = lines( lt_lot_rows ).
      lv_total += lv_lot_cnt.
      _post_results(
        iv_prueflos  = lv_lot
        iv_filename  = iv_filename
        it_rows      = lt_lot_rows
        iv_overwrite = iv_overwrite
      ).
      lv_detail &&= |  { lv_lot }: { lv_lot_cnt } { condense( TEXT-003 ) }\n|.
    ENDLOOP.
    rv_msg = |{ lines( lt_lots ) } { condense( TEXT-004 ) } { lv_total } { condense( TEXT-005 ) }\n| && lv_detail.
  ENDMETHOD.


  METHOD _post_results.
    DATA lv_ul_status TYPE ty_ul_status.
    lv_ul_status = `S`.

    DATA(lt_ops) = _collect_operations( it_rows ).

    LOOP AT lt_ops INTO DATA(lv_vornr).
      IF iv_overwrite = abap_true.
        LOOP AT it_rows INTO DATA(ls_ow) WHERE vorgangsnummer = lv_vornr.
          _invalidate_char(
            iv_prueflos = iv_prueflos
            iv_inspoper = CONV vornr( lv_vornr )
            iv_inspchar = CONV qamv-merknr( ls_ow-merkmalsnummer )
          ).
        ENDLOOP.
      ENDIF.

      DATA(ls_input)   = _build_bapi_input(
        iv_prueflos  = iv_prueflos
        iv_vornr     = lv_vornr
        iv_filename  = iv_filename
        it_rows      = it_rows
        iv_overwrite = iv_overwrite
      ).
      DATA ls_return   TYPE bapiret2.
      DATA lt_return   TYPE ty_return_tab.
      CLEAR lt_return.
      CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
        EXPORTING insplot        = iv_prueflos
                  inspoper       = CONV vornr( lv_vornr )
        IMPORTING return         = ls_return
        TABLES    char_results   = ls_input-char_results
                  sample_results = ls_input-sample_results
                  single_results = ls_input-single_results
                  returntable    = lt_return.

      CALL METHOD _write_prot_for_operation
        EXPORTING iv_prueflos  = iv_prueflos
                  iv_filename  = iv_filename
                  it_rows      = it_rows
                  iv_vornr     = lv_vornr
                  it_return    = lt_return
        CHANGING  cv_ul_status = lv_ul_status.
    ENDLOOP.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = `X`.
    _update_status(
      iv_prueflos = iv_prueflos
      iv_status   = lv_ul_status
    ).
  ENDMETHOD.


  METHOD _collect_operations.
    LOOP AT it_rows INTO DATA(ls_row).
      INSERT condense( ls_row-vorgangsnummer ) INTO TABLE rt_ops.
    ENDLOOP.
    SORT rt_ops BY table_line.
    DELETE ADJACENT DUPLICATES FROM rt_ops COMPARING table_line.
  ENDMETHOD.


  METHOD _build_bapi_input.
    DATA lv_steuerkz TYPE qamv-steuerkz.
    DATA ls_qmkst    TYPE qmkst.
    FIELD-SYMBOLS <fs_qmkst> TYPE qmkst.

    DATA lv_radii_kurztext TYPE string.
    DATA ls_radii_code     TYPE ty_up_code.
    LOOP AT it_rows INTO DATA(ls_row) WHERE vorgangsnummer = iv_vornr.
      CLEAR: lv_radii_kurztext, ls_radii_code.
      IF ls_row-radii_1 IS NOT INITIAL AND ls_row-radii_2 IS INITIAL.
        lv_radii_kurztext = ls_row-radii_1.
      ELSEIF ls_row-radii_2 IS NOT INITIAL AND ls_row-radii_1 IS INITIAL.
        lv_radii_kurztext = ls_row-radii_2.
      ENDIF.
      IF lv_radii_kurztext IS NOT INITIAL.
        ls_radii_code = _get_radii_code(
          iv_prueflos = iv_prueflos
          iv_vornr    = condense( ls_row-vorgangsnummer )
          iv_merknr   = condense( ls_row-merkmalsnummer )
          iv_kurztext = lv_radii_kurztext
        ).
      ENDIF.

      lv_steuerkz = _get_qamv_steuerkz(
        iv_prueflos = iv_prueflos
        iv_vornr    = condense( ls_row-vorgangsnummer )
        iv_merknr   = condense( ls_row-merkmalsnummer )
      ).
      ASSIGN lv_steuerkz TO <fs_qmkst> CASTING.
      ls_qmkst = <fs_qmkst>.

      CASE ls_qmkst-estukz.
        WHEN `+`.
          DATA(lv_eval)     = _get_evaluation(
            iv_prueflos = iv_prueflos
            iv_vornr    = condense( ls_row-vorgangsnummer )
            iv_merknr   = condense( ls_row-merkmalsnummer )
            iv_messwert = ls_row-messwert
          ).
          DATA lv_ep_codegrp TYPE qpac-codegruppe.
          DATA lv_ep_code    TYPE qpac-code.
          CLEAR: lv_ep_codegrp, lv_ep_code.
          DATA lv_res_no TYPE numc4.
          IF iv_overwrite = abap_true.
            lv_res_no = 1.
          ELSE.
            lv_res_no = _get_next_res_no(
              iv_prueflos = iv_prueflos
              iv_inspoper = CONV vornr( iv_vornr )
              iv_inspchar = CONV qamv-merknr( ls_row-merkmalsnummer )
            ).
          ENDIF.
          IF ls_row-quanqual = `QN`.
            INSERT VALUE bapi2045d4(
              insplot    = iv_prueflos
              inspoper   = iv_vornr
              inspchar   = ls_row-merkmalsnummer
              res_no     = lv_res_no
              res_value  = ls_row-messwert
              res_valuat = lv_eval
              code_grp2  = ls_radii_code-codegruppe
              code2      = ls_radii_code-code
              inspector  = sy-uname
              insp_date  = sy-datum
              insp_time  = sy-uzeit
              remark     = iv_filename
            ) INTO TABLE rs_input-single_results.
          ELSE.
            IF ls_row-code_col_idx > 0.
              DATA(lt_ep_codes) = _get_codes_for_char(
                iv_prueflos = iv_prueflos
                iv_vornr    = condense( ls_row-vorgangsnummer )
                iv_merknr   = condense( ls_row-merkmalsnummer )
              ).
              READ TABLE lt_ep_codes INDEX ( ls_row-code_col_idx - 28 )
                INTO DATA(ls_ep_code).
              IF sy-subrc = 0.
                IF ls_ep_code-bewertung IS NOT INITIAL.
                  lv_eval = ls_ep_code-bewertung.
                ENDIF.
                lv_ep_codegrp = ls_ep_code-codegruppe.
                lv_ep_code    = ls_ep_code-code.
                INSERT VALUE bapi2045d4(
                  insplot    = iv_prueflos
                  inspoper   = iv_vornr
                  inspchar   = ls_row-merkmalsnummer
                  res_no     = lv_res_no
                  code_grp1  = lv_ep_codegrp
                  code1      = lv_ep_code
                  code_grp2  = ls_radii_code-codegruppe
                  code2      = ls_radii_code-code
                  res_valuat = lv_eval
                  inspector  = sy-uname
                  insp_date  = sy-datum
                  insp_time  = sy-uzeit
                  remark     = iv_filename
                ) INTO TABLE rs_input-single_results.
              ENDIF.
            ENDIF.
          ENDIF.
          INSERT VALUE bapi2045d2(
            insplot          = iv_prueflos
            inspoper         = iv_vornr
            inspchar         = ls_row-merkmalsnummer
            code_grp1        = lv_ep_codegrp
            code1            = lv_ep_code
            code_grp2        = ls_radii_code-codegruppe
            code2            = ls_radii_code-code
            closed           = `X`
            evaluation       = lv_eval
            condition_active = `X`
            res_org          = `ZA`
            remark           = iv_filename
          ) INTO TABLE rs_input-char_results.

        WHEN `=`.
          INSERT VALUE bapi2045d3(
            inspchar   = ls_row-merkmalsnummer
            mean_value = ls_row-messwert
            closed     = `X`
            remark     = iv_filename
          ) INTO TABLE rs_input-sample_results.

        WHEN OTHERS.
          IF ls_row-code_col_idx > 0.
            DATA(lt_codes) = _get_codes_for_char(
              iv_prueflos = iv_prueflos
              iv_vornr    = condense( ls_row-vorgangsnummer )
              iv_merknr   = condense( ls_row-merkmalsnummer )
            ).
            READ TABLE lt_codes INDEX ( ls_row-code_col_idx - 28 )
              INTO DATA(ls_code).
            IF sy-subrc = 0.
              INSERT VALUE bapi2045d2(
                inspchar  = ls_row-merkmalsnummer
                code_grp1 = ls_code-codegruppe
                code1     = ls_code-code
                code_grp2 = ls_radii_code-codegruppe
                code2     = ls_radii_code-code
                closed    = `X`
                remark    = iv_filename
              ) INTO TABLE rs_input-char_results.
            ENDIF.
          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD _write_prot_for_operation.
    " Ersten Fehler für alle Zeilen dieser Operation ermitteln (BAPI-Ergebnis ist pro Vorgang)
    READ TABLE it_return INTO DATA(ls_error) WITH KEY type = `E`.
    IF sy-subrc <> 0.
      READ TABLE it_return INTO ls_error WITH KEY type = `A`.
    ENDIF.
    DATA(lv_has_error) = xsdbool( sy-subrc = 0 ).

    LOOP AT it_rows INTO DATA(ls_row) WHERE vorgangsnummer = iv_vornr.
      DATA(ls_entry) = VALUE ty_prot_entry(
        prueflos  = iv_prueflos
        filename  = iv_filename
        excel_row = ls_row-excel_row
        inspoper  = condense( ls_row-vorgangsnummer )
        merknr    = condense( ls_row-merkmalsnummer )
      ).
      IF lv_has_error = abap_true.
        ls_entry-status = `E`.
        ls_entry-msg    = ls_error-message.
        cv_ul_status    = `E`.
      ELSE.
        ls_entry-status = `S`.
        ls_entry-msg    = _build_success_prot_msg(
          iv_prueflos = iv_prueflos
          iv_vornr    = iv_vornr
          is_row      = ls_row
        ).
      ENDIF.
      _write_prot( ls_entry ).
    ENDLOOP.
  ENDMETHOD.


  METHOD _build_success_prot_msg.
    IF is_row-quanqual = `QN`.
      DATA(lv_eval) = _get_evaluation(
        iv_prueflos = iv_prueflos
        iv_vornr    = condense( is_row-vorgangsnummer )
        iv_merknr   = condense( is_row-merkmalsnummer )
        iv_messwert = is_row-messwert
      ).
      rv_msg = |{ condense( TEXT-006 ) } { lv_eval } - { is_row-messwert }|.
      RETURN.
    ENDIF.
    IF is_row-code_col_idx > 0.
      DATA(lt_codes) = _get_codes_for_char(
        iv_prueflos = iv_prueflos
        iv_vornr    = condense( is_row-vorgangsnummer )
        iv_merknr   = condense( is_row-merkmalsnummer )
      ).
      READ TABLE lt_codes INDEX ( is_row-code_col_idx - 28 ) INTO DATA(ls_code).
      IF sy-subrc = 0.
        rv_msg = |{ condense( TEXT-006 ) } { ls_code-bewertung } - { condense( ls_code-kurztext ) }|.
        RETURN.
      ENDIF.
    ENDIF.
    rv_msg = TEXT-007.
  ENDMETHOD.


  METHOD _col_letter_to_idx.
    CONSTANTS lc_alphabet TYPE c LENGTH 26 VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    DATA(lv_upper) = to_upper( iv_col ).
    DATA(lv_len)   = strlen( lv_upper ).
    DATA lv_pos    TYPE i.
    rv_idx = 0.
    DO lv_len TIMES.
      DATA(lv_off) = sy-index - 1.
      DATA(lv_ch)  = lv_upper+lv_off(1).
      FIND lv_ch IN lc_alphabet MATCH OFFSET lv_pos.
      rv_idx = rv_idx * 26 + lv_pos + 1.
    ENDDO.
  ENDMETHOD.


  METHOD _parse_xlsx.
    " Unterstützt beide XLSX-Formate:
    "   inlineStr (t="inlineStr"): <is><t>text</t></is>  -- von unserem Download erzeugt
    "   Shared Strings (t="s"):   <v>N</v> + xl/sharedStrings.xml  -- Excel nach erneutem Speichern
    "   Numerisch (kein t):       <v>wert</v>
    DATA lv_xml_raw   TYPE xstring.
    DATA lv_xml       TYPE string.
    DATA ls_row       TYPE ty_upload_row.
    DATA lv_row_nr    TYPE i.
    DATA lt_shared    TYPE TABLE OF string WITH EMPTY KEY.
    DATA lv_ss_rest   TYPE string.
    DATA lv_si_start  TYPE i.
    DATA lv_si_end    TYPE i.
    DATA lv_si_xml    TYPE string.
    DATA lv_t_s       TYPE i.
    DATA lv_t_e       TYPE i.
    DATA lv_t_tag_len TYPE i.
    DATA lv_ss_val    TYPE string.
    DATA lv_rest      TYPE string.
    DATA lv_rowxml    TYPE string.
    DATA lv_rownum    TYPE string.
    DATA lv_end       TYPE i.
    DATA lv_cell_rest TYPE string.
    DATA lv_col_let   TYPE string.
    DATA lv_cell_val  TYPE string.
    DATA lv_cell_type TYPE string.
    DATA lv_col_idx   TYPE i.
    DATA lv_c_end     TYPE i.
    DATA lv_c_len     TYPE i.
    DATA lv_cell_xml  TYPE string.
    DATA lv_v_s       TYPE i.
    DATA lv_v_e       TYPE i.
    DATA lv_idx       TYPE i.
    DATA lv_t_start   TYPE i.
    DATA lv_t_end     TYPE i.
    DATA lv_t_off     TYPE i.
    DATA lv_t_len     TYPE i.

    DATA(lo_zip) = NEW cl_abap_zip( ).
    lo_zip->load( EXPORTING zip = iv_xstring EXCEPTIONS others = 1 ).
    CHECK sy-subrc = 0.

    " ── Shared Strings laden (xl/sharedStrings.xml) ────────────────────────
    lo_zip->get( EXPORTING name    = 'xl/sharedStrings.xml'
                 IMPORTING content = lv_xml_raw EXCEPTIONS others = 1 ).
    IF sy-subrc = 0.
      DATA(lv_ss_xml) = cl_abap_codepage=>convert_from( source = lv_xml_raw codepage = 'UTF-8' ).
      lv_ss_rest = lv_ss_xml.
      FIND FIRST OCCURRENCE OF `<si>` IN lv_ss_rest MATCH OFFSET lv_si_start.
      WHILE sy-subrc = 0.
        FIND FIRST OCCURRENCE OF `</si>` IN lv_ss_rest MATCH OFFSET lv_si_end.
        IF sy-subrc <> 0. EXIT. ENDIF.
        lv_si_xml = substring( val = lv_ss_rest off = lv_si_start
                               len = lv_si_end - lv_si_start ).
        " <t ...>text</t> — ggf. mit xml:space Attribut
        FIND FIRST OCCURRENCE OF PCRE `<t[^>]*>` IN lv_si_xml
          MATCH OFFSET lv_t_s MATCH LENGTH lv_t_tag_len.
        FIND FIRST OCCURRENCE OF `</t>` IN lv_si_xml MATCH OFFSET lv_t_e.
        IF sy-subrc = 0 AND lv_t_e > lv_t_s + lv_t_tag_len.
          lv_ss_val = substring( val = lv_si_xml off = lv_t_s + lv_t_tag_len
                                 len = lv_t_e - lv_t_s - lv_t_tag_len ).
        ELSE.
          CLEAR lv_ss_val.
        ENDIF.
        INSERT lv_ss_val INTO TABLE lt_shared.
        lv_ss_rest = substring( val = lv_ss_rest off = lv_si_end + 5 ).
        FIND FIRST OCCURRENCE OF `<si>` IN lv_ss_rest MATCH OFFSET lv_si_start.
      ENDWHILE.
    ENDIF.

    " ── Worksheet laden (xl/worksheets/sheet1.xml) ─────────────────────────
    CLEAR lv_xml_raw.
    lo_zip->get( EXPORTING name    = 'xl/worksheets/sheet1.xml'
                 IMPORTING content = lv_xml_raw EXCEPTIONS others = 1 ).
    CHECK sy-subrc = 0.
    lv_xml  = cl_abap_codepage=>convert_from( source = lv_xml_raw codepage = 'UTF-8' ).
    lv_rest = lv_xml.

    FIND FIRST OCCURRENCE OF PCRE `<row[\s][^>]*r="(\d+)"` IN lv_rest SUBMATCHES lv_rownum.
    WHILE sy-subrc = 0.
      FIND FIRST OCCURRENCE OF `</row>` IN lv_rest MATCH OFFSET lv_end.
      lv_rowxml = substring( val = lv_rest off = 0 len = lv_end ).
      lv_rest   = substring( val = lv_rest off = lv_end + 6 ).
      IF lv_rownum = '1'.
        FIND FIRST OCCURRENCE OF PCRE `<row[\s][^>]*r="(\d+)"` IN lv_rest SUBMATCHES lv_rownum.
        CONTINUE.
      ENDIF.
      lv_row_nr = lv_rownum.
      CLEAR ls_row.
      ls_row-excel_row = lv_row_nr.
      lv_cell_rest = lv_rowxml.

      FIND FIRST OCCURRENCE OF PCRE `<c[\s][^>]*r="([A-Z]+)\d+"` IN lv_cell_rest SUBMATCHES lv_col_let.
      WHILE sy-subrc = 0.
        FIND FIRST OCCURRENCE OF `</c>` IN lv_cell_rest MATCH OFFSET lv_c_end.
        IF sy-subrc <> 0. EXIT. ENDIF.
        lv_c_len    = lv_c_end + 4.
        lv_cell_xml = substring( val = lv_cell_rest off = 0 len = lv_c_len ).

        FIND FIRST OCCURRENCE OF PCRE `\bt="([^"]*)"` IN lv_cell_xml SUBMATCHES lv_cell_type.
        IF sy-subrc <> 0. CLEAR lv_cell_type. ENDIF.

        CASE lv_cell_type.
          WHEN 's'.
            FIND FIRST OCCURRENCE OF `<v>` IN lv_cell_xml MATCH OFFSET lv_v_s.
            FIND FIRST OCCURRENCE OF `</v>` IN lv_cell_xml MATCH OFFSET lv_v_e.
            IF sy-subrc = 0.
              lv_idx = substring( val = lv_cell_xml off = lv_v_s + 3
                                  len = lv_v_e - lv_v_s - 3 ).
              READ TABLE lt_shared INDEX lv_idx + 1 INTO lv_cell_val.
              IF sy-subrc <> 0. CLEAR lv_cell_val. ENDIF.
            ELSE.
              CLEAR lv_cell_val.
            ENDIF.
          WHEN 'inlineStr'.
            FIND FIRST OCCURRENCE OF `<t>` IN lv_cell_xml MATCH OFFSET lv_t_start.
            FIND FIRST OCCURRENCE OF `</t>` IN lv_cell_xml MATCH OFFSET lv_t_end.
            IF sy-subrc = 0.
              lv_t_off = lv_t_start + 3.
              lv_t_len = lv_t_end - lv_t_off.
              lv_cell_val = COND #( WHEN lv_t_len > 0
                                    THEN substring( val = lv_cell_xml off = lv_t_off len = lv_t_len )
                                    ELSE `` ).
            ELSE.
              CLEAR lv_cell_val.
            ENDIF.
          WHEN OTHERS.
            FIND FIRST OCCURRENCE OF `<v>` IN lv_cell_xml MATCH OFFSET lv_v_s.
            FIND FIRST OCCURRENCE OF `</v>` IN lv_cell_xml MATCH OFFSET lv_v_e.
            IF sy-subrc = 0.
              lv_cell_val = substring( val = lv_cell_xml off = lv_v_s + 3
                                       len = lv_v_e - lv_v_s - 3 ).
            ELSE.
              CLEAR lv_cell_val.
            ENDIF.
        ENDCASE.

        lv_col_idx = _col_letter_to_idx( lv_col_let ).
        CASE lv_col_idx.
          WHEN 1.  ls_row-prueflosnummer = condense( lv_cell_val ).
          WHEN 10. ls_row-vorgangsnummer = condense( lv_cell_val ).
          WHEN 15. ls_row-quanqual       = condense( lv_cell_val ).
          WHEN 16. ls_row-merkmalsnummer = condense( lv_cell_val ).
          WHEN 27.
            IF condense( lv_cell_val ) <> ``.
              ls_row-radii_1 = condense( lv_cell_val ).
            ENDIF.
          WHEN 28.
            IF condense( lv_cell_val ) <> ``.
              ls_row-radii_2 = condense( lv_cell_val ).
            ENDIF.
          WHEN OTHERS.
            IF lv_col_idx >= 29 AND condense( lv_cell_val ) <> ``.
              IF ls_row-quanqual = `QN`.
                ls_row-messwert = condense( lv_cell_val ).
              ELSE.
                IF ls_row-code_col_idx = 0.
                  ls_row-code_col_idx = lv_col_idx.
                ENDIF.
              ENDIF.
            ENDIF.
        ENDCASE.

        lv_cell_rest = substring( val = lv_cell_rest off = lv_c_end + 4 ).
        FIND FIRST OCCURRENCE OF PCRE `<c[\s][^>]*r="([A-Z]+)\d+"` IN lv_cell_rest SUBMATCHES lv_col_let.
      ENDWHILE.

      IF ls_row-prueflosnummer IS NOT INITIAL AND ls_row-merkmalsnummer IS NOT INITIAL.
        INSERT ls_row INTO TABLE rt_rows.
      ENDIF.
      FIND FIRST OCCURRENCE OF PCRE `<row[\s][^>]*r="(\d+)"` IN lv_rest SUBMATCHES lv_rownum.
    ENDWHILE.
  ENDMETHOD.


  METHOD _get_codes_for_char.
    DATA lv_vorglfnr TYPE qamv-vorglfnr.
    SELECT SINGLE InspPlanOperationInternalID
      FROM ZJMQMI_I_INSPLOT_CHAR
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @lv_vorglfnr.
    CHECK sy-subrc = 0.
    DATA ls_qamv TYPE qamv.
    SELECT SINGLE katalgart1, auswmenge1, auswmgwrk1
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @lv_vorglfnr
        AND merknr   = @iv_merknr
      INTO CORRESPONDING FIELDS OF @ls_qamv.
    CHECK sy-subrc = 0
      AND ls_qamv-katalgart1 IS NOT INITIAL
      AND ls_qamv-auswmenge1 IS NOT INITIAL.
    SELECT qpac~codegruppe, qpac~code, qpac~bewertung, qpct~kurztext
      FROM qpac
      INNER JOIN qpct
        ON  qpct~katalogart = qpac~katalogart
        AND qpct~codegruppe = qpac~codegruppe
        AND qpct~code       = qpac~code
        AND qpct~sprache    = @sy-langu
      WHERE qpac~katalogart = @ls_qamv-katalgart1
        AND qpac~werks      = @ls_qamv-auswmgwrk1
        AND qpac~auswahlmge = @ls_qamv-auswmenge1
      ORDER BY qpac~code
      INTO CORRESPONDING FIELDS OF TABLE @rt_codes.
  ENDMETHOD.


  METHOD _write_prot.
    DATA lv_guid TYPE sysuuid_c32.
    TRY.
        lv_guid = cl_system_uuid=>create_uuid_c32_static( ).
      CATCH cx_uuid_error.
        GET TIME STAMP FIELD DATA(lv_fb_ts).
        lv_guid = |{ sy-uname }{ lv_fb_ts }|.
    ENDTRY.
    DATA ls_prot TYPE zjmqmit_prot.
    GET TIME STAMP FIELD ls_prot-prot_timestamp.
    ls_prot-prueflos       = entry-prueflos.
    ls_prot-prot_guid      = lv_guid.
    ls_prot-prot_filename  = entry-filename.
    ls_prot-prot_rownr     = entry-excel_row.
    ls_prot-prot_inspoper  = entry-inspoper.
    ls_prot-prot_insp_char = entry-merknr.
    ls_prot-prot_status    = entry-status.
    ls_prot-prot_msg       = entry-msg.
    ls_prot-created_by     = sy-uname.
    ls_prot-created_at     = ls_prot-prot_timestamp.
    INSERT zjmqmit_prot FROM ls_prot.
  ENDMETHOD.


  METHOD _update_status.
    GET TIME STAMP FIELD DATA(lv_ts).
    UPDATE zjmqmit_status
      SET last_ul_at     = @lv_ts,
          last_ul_by     = @sy-uname,
          last_ul_status = @iv_status
      WHERE prueflos = @iv_prueflos.
    IF sy-subrc <> 0.
      DATA ls_stat TYPE zjmqmit_status.
      ls_stat-prueflos       = iv_prueflos.
      ls_stat-last_ul_at     = lv_ts.
      ls_stat-last_ul_by     = sy-uname.
      ls_stat-last_ul_status = iv_status.
      INSERT zjmqmit_status FROM ls_stat.
    ENDIF.
  ENDMETHOD.


  METHOD _get_qamv_steuerkz.
    DATA lv_vorglfnr TYPE qamv-vorglfnr.
    SELECT SINGLE InspPlanOperationInternalID
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @lv_vorglfnr.
    CHECK sy-subrc = 0.
    SELECT SINGLE steuerkz
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @lv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @rv_steuerkz.
  ENDMETHOD.


  METHOD _get_evaluation.
    rv_result = `A`.
    CHECK iv_messwert IS NOT INITIAL.
    SELECT SINGLE InspSpecUpperLimit, InspSpecLowerLimit
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(ls_lim).
    CHECK sy-subrc = 0.
    " Dezimaltrenner normalisieren (Komma → Punkt)
    DATA(lv_val_str) = iv_messwert.
    REPLACE ALL OCCURRENCES OF ',' IN lv_val_str WITH '.'.
    TRY.
        DATA(lv_val) = CONV decfloat34( lv_val_str ).
        IF ls_lim-InspSpecUpperLimit IS NOT INITIAL
           AND lv_val > CONV decfloat34( ls_lim-InspSpecUpperLimit ).
          rv_result = `R`.
        ELSEIF ls_lim-InspSpecLowerLimit IS NOT INITIAL
           AND lv_val < CONV decfloat34( ls_lim-InspSpecLowerLimit ).
          rv_result = `R`.
        ENDIF.
      CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
        " Kein Vergleich möglich → Annahme beibehalten
    ENDTRY.
  ENDMETHOD.


  METHOD _get_next_res_no.
    DATA lt_singl TYPE TABLE OF bapi2045d4.
    CALL FUNCTION 'BAPI_INSPCHAR_GETRESULT'
      EXPORTING insplot        = iv_prueflos
                inspoper       = iv_inspoper
                inspchar       = iv_inspchar
      TABLES    single_results = lt_singl.
    rv_next = lines( lt_singl ) + 1.
  ENDMETHOD.


  METHOD _get_radii_code.
    DATA lv_vorglfnr TYPE qamv-vorglfnr.
    SELECT SINGLE InspPlanOperationInternalID
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @lv_vorglfnr.
    CHECK sy-subrc = 0.
    SELECT SINGLE katalgart2, auswmenge2
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @lv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @DATA(ls_qamv).
    CHECK sy-subrc = 0
      AND ls_qamv-katalgart2 = `E`
      AND ls_qamv-auswmenge2 IS NOT INITIAL.
    SELECT SINGLE code, codegruppe
      FROM qpct
      WHERE katalogart = @ls_qamv-katalgart2
        AND codegruppe = @ls_qamv-auswmenge2
        AND sprache    = @sy-langu
        AND kurztext   = @iv_kurztext
      INTO @DATA(ls_pct).
    CHECK sy-subrc = 0.
    rs_code-code       = ls_pct-code.
    rs_code-codegruppe = ls_pct-codegruppe.
  ENDMETHOD.


  METHOD _invalidate_char.
    " closed = ' ' + evaluation = ' ' setzt das Merkmal auf "offen / nicht bewertet" zurück,
    " damit neue Ergebnisse ohne Bewertungskonflikt gebucht werden können.
    DATA lt_char TYPE TABLE OF bapi2045d2 WITH EMPTY KEY.
    INSERT VALUE bapi2045d2(
      insplot    = iv_prueflos
      inspoper   = iv_inspoper
      inspchar   = iv_inspchar
      closed     = ' '
      evaluation = ' '
    ) INTO TABLE lt_char.
    DATA ls_ret TYPE bapiret2.
    CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
      EXPORTING insplot      = iv_prueflos
                inspoper     = iv_inspoper
      IMPORTING return       = ls_ret
      TABLES    char_results = lt_char.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = `X`.
  ENDMETHOD.

ENDCLASS.

