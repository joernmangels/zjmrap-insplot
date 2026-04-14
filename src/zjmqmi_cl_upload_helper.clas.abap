CLASS zjmqmi_cl_upload_helper DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_filter_lots TYPE STANDARD TABLE OF qals-prueflos WITH EMPTY KEY.
    METHODS process_upload
      IMPORTING iv_filename    TYPE string
                iv_xstring     TYPE xstring
                it_filter_lots TYPE ty_filter_lots OPTIONAL
      RETURNING VALUE(rv_msg) TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_upload_row,
             prueflosnummer TYPE c LENGTH 18,
             vorgangsnummer TYPE c LENGTH 4,
             quanqual       TYPE c LENGTH 2,
             merkmalsnummer TYPE c LENGTH 4,
             messwert       TYPE string,
             code_col_idx   TYPE i,
             excel_row      TYPE i,
           END OF ty_upload_row.
    TYPES ty_upload_rows TYPE STANDARD TABLE OF ty_upload_row WITH EMPTY KEY.
    TYPES: BEGIN OF ty_up_code,
             code       TYPE qpac-code,
             codegruppe TYPE qpac-codegruppe,
             bewertung  TYPE qpac-bewertung,
             kurztext   TYPE qpct-kurztext,
           END OF ty_up_code.
    TYPES ty_up_codes TYPE STANDARD TABLE OF ty_up_code WITH EMPTY KEY.

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

    METHODS _write_prot
      IMPORTING iv_prueflos  TYPE qals-prueflos
                iv_filename  TYPE string
                iv_excel_row TYPE i
                iv_inspoper  TYPE string
                iv_merknr    TYPE string
                iv_status    TYPE c
                iv_msg       TYPE string.

    METHODS _update_status
      IMPORTING iv_prueflos TYPE qals-prueflos
                iv_status   TYPE c.

    METHODS _post_results
      IMPORTING iv_prueflos TYPE qals-prueflos
                iv_filename TYPE string
                it_rows     TYPE ty_upload_rows.
ENDCLASS.

CLASS zjmqmi_cl_upload_helper IMPLEMENTATION.

  METHOD process_upload.
    DATA(lt_rows) = _parse_xlsx( iv_xstring ).
    IF lt_rows IS INITIAL.
      rv_msg = 'Keine Daten in der Excel-Datei gefunden'.
      RETURN.
    ENDIF.
    DATA lt_lots TYPE TABLE OF qals-prueflos WITH EMPTY KEY.
    LOOP AT lt_rows INTO DATA(ls_r).
      APPEND CONV qals-prueflos( condense( ls_r-prueflosnummer ) ) TO lt_lots.
    ENDLOOP.
    SORT lt_lots BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_lots COMPARING table_line.
    " Wenn Filter-Lots übergeben: nur diese verarbeiten
    IF it_filter_lots IS NOT INITIAL.
      DELETE lt_lots WHERE NOT table_line IN
        VALUE rseloption( FOR lv IN it_filter_lots
                          ( sign = 'I' option = 'EQ' low = lv ) ).
    ENDIF.
    IF lt_lots IS INITIAL.
      rv_msg = 'Keine passenden Prüflose in der Excel-Datei gefunden'.
      RETURN.
    ENDIF.
    LOOP AT lt_lots INTO DATA(lv_lot).
      DATA(lt_lot_rows) = VALUE ty_upload_rows(
        FOR r IN lt_rows WHERE ( prueflosnummer = lv_lot ) ( r )
      ).
      _post_results(
        iv_prueflos = lv_lot
        iv_filename = iv_filename
        it_rows     = lt_lot_rows
      ).
    ENDLOOP.
    rv_msg = |{ lines( lt_rows ) } Merkmal(e) aus { lines( lt_lots ) } Prüflos(en) verarbeitet|.
  ENDMETHOD.

  METHOD _col_letter_to_idx.
    DATA lc     TYPE c LENGTH 26.
    DATA lv_col TYPE c LENGTH 10.
    DATA lv_ch  TYPE c LENGTH 1.
    DATA lv_pos TYPE i.
    DATA lv_len TYPE i.
    DATA lv_off TYPE i.
    lc     = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    lv_col = to_upper( iv_col ).
    lv_len = strlen( lv_col ).
    rv_idx = 0.
    DO lv_len TIMES.
      lv_off = sy-index - 1.
      lv_ch  = lv_col+lv_off(1).
      FIND lv_ch IN lc MATCH OFFSET lv_pos.
      rv_idx = rv_idx * 26 + lv_pos + 1.
    ENDDO.
  ENDMETHOD.

  METHOD _parse_xlsx.
    " Unterstützt beide XLSX-Formate:
    "   inlineStr (t="inlineStr"): <is><t>text</t></is>  -- von unserem Download erzeugt
    "   Shared Strings (t="s"):   <v>N</v> + xl/sharedStrings.xml  -- Excel nach erneutem Speichern
    "   Numerisch (kein t):       <v>wert</v>
    DATA lo_zip       TYPE REF TO cl_abap_zip.
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

    CREATE OBJECT lo_zip.
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
        APPEND lv_ss_val TO lt_shared.
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
        " Zell-XML bis einschließlich </c> extrahieren
        FIND FIRST OCCURRENCE OF `</c>` IN lv_cell_rest MATCH OFFSET lv_c_end.
        IF sy-subrc <> 0. EXIT. ENDIF.
        lv_c_len    = lv_c_end + 4.
        lv_cell_xml = substring( val = lv_cell_rest off = 0 len = lv_c_len ).

        " Typ-Attribut lesen (t="s" | t="inlineStr" | kein t = numerisch)
        FIND FIRST OCCURRENCE OF PCRE `\bt="([^"]*)"` IN lv_cell_xml SUBMATCHES lv_cell_type.
        IF sy-subrc <> 0. CLEAR lv_cell_type. ENDIF.

        " Wert je nach Typ extrahieren
        CASE lv_cell_type.
          WHEN 's'.
            " Shared String: <v>N</v> → Lookup in lt_shared
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
            " Inline String: <is><t>text</t></is>
            FIND FIRST OCCURRENCE OF `<t>` IN lv_cell_xml MATCH OFFSET lv_t_start.
            FIND FIRST OCCURRENCE OF `</t>` IN lv_cell_xml MATCH OFFSET lv_t_end.
            IF sy-subrc = 0.
              lv_t_off = lv_t_start + 3.
              lv_t_len = lv_t_end - lv_t_off.
              lv_cell_val = COND #( WHEN lv_t_len > 0
                                    THEN substring( val = lv_cell_xml off = lv_t_off len = lv_t_len )
                                    ELSE '' ).
            ELSE.
              CLEAR lv_cell_val.
            ENDIF.
          WHEN OTHERS.
            " Numerisch / kein Typ: <v>wert</v>
            FIND FIRST OCCURRENCE OF `<v>` IN lv_cell_xml MATCH OFFSET lv_v_s.
            FIND FIRST OCCURRENCE OF `</v>` IN lv_cell_xml MATCH OFFSET lv_v_e.
            IF sy-subrc = 0.
              lv_cell_val = substring( val = lv_cell_xml off = lv_v_s + 3
                                       len = lv_v_e - lv_v_s - 3 ).
            ELSE.
              CLEAR lv_cell_val.
            ENDIF.
        ENDCASE.

        " Spaltenzuordnung
        lv_col_idx = _col_letter_to_idx( lv_col_let ).
        CASE lv_col_idx.
          WHEN 1.  ls_row-prueflosnummer = condense( lv_cell_val ).
          WHEN 10. ls_row-vorgangsnummer = condense( lv_cell_val ).
          WHEN 15. ls_row-quanqual       = condense( lv_cell_val ).
          WHEN 16. ls_row-merkmalsnummer = condense( lv_cell_val ).
          WHEN OTHERS.
            IF lv_col_idx >= 27 AND condense( lv_cell_val ) <> ''.
              IF ls_row-quanqual = 'QN'.
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
        APPEND ls_row TO rt_rows.
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
    DATA ls_prot TYPE zjmqmit_prot.
    DATA lv_guid TYPE sysuuid_c32.
    TRY.
      lv_guid = cl_system_uuid=>create_uuid_c32_static( ).
    CATCH cx_uuid_error.
      GET TIME STAMP FIELD DATA(lv_fb_ts).
      lv_guid = |{ sy-uname }{ lv_fb_ts }|.
    ENDTRY.
    GET TIME STAMP FIELD ls_prot-prot_timestamp.
    ls_prot-prueflos       = iv_prueflos.
    ls_prot-prot_guid      = lv_guid.
    ls_prot-prot_filename  = iv_filename.
    ls_prot-prot_rownr     = iv_excel_row.
    ls_prot-prot_inspoper  = iv_inspoper.
    ls_prot-prot_insp_char = iv_merknr.
    ls_prot-prot_status    = iv_status.
    ls_prot-prot_msg       = iv_msg.
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
    " Standardmäßig Annahme
    rv_result = 'A'.
    CHECK iv_messwert IS NOT INITIAL.
    " Grenzen aus CDS lesen
    SELECT SINGLE InspSpecUpperLimit, InspSpecLowerLimit
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(ls_lim).
    CHECK sy-subrc = 0.
    " Messwert konvertieren (Komma→Punkt für ABAP-Dezimaltrenner)
    DATA lv_val_str TYPE string.
    lv_val_str = iv_messwert.
    REPLACE ALL OCCURRENCES OF ',' IN lv_val_str WITH '.'.
    TRY.
      DATA(lv_val) = CONV decfloat34( lv_val_str ).
      IF ls_lim-InspSpecUpperLimit IS NOT INITIAL
         AND lv_val > CONV decfloat34( ls_lim-InspSpecUpperLimit ).
        rv_result = 'R'.
      ELSEIF ls_lim-InspSpecLowerLimit IS NOT INITIAL
         AND lv_val < CONV decfloat34( ls_lim-InspSpecLowerLimit ).
        rv_result = 'R'.
      ENDIF.
    CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
      " Kein Vergleich möglich → Annahme behalten
  ENDTRY.
  ENDMETHOD.

  METHOD _get_next_res_no.
    DATA lt_singl TYPE TABLE OF bapi2045d4.
    DATA lv_count TYPE i.
    CALL FUNCTION 'BAPI_INSPCHAR_GETRESULT'
      EXPORTING insplot        = iv_prueflos
                inspoper       = iv_inspoper
                inspchar       = iv_inspchar
      TABLES    single_results = lt_singl.
    DESCRIBE TABLE lt_singl LINES lv_count.
    rv_next = lv_count + 1.
  ENDMETHOD.

  METHOD _post_results.
    DATA lt_vorgnr TYPE TABLE OF string WITH EMPTY KEY.
    LOOP AT it_rows INTO DATA(ls_r).
      APPEND condense( ls_r-vorgangsnummer ) TO lt_vorgnr.
    ENDLOOP.
    SORT lt_vorgnr BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_vorgnr COMPARING table_line.
    DATA lv_ul_status TYPE c LENGTH 1.
    lv_ul_status = 'S'.
    DATA lv_steuerkz  TYPE qamv-steuerkz.
    DATA ls_qmkst     TYPE qmkst.
    FIELD-SYMBOLS <fs_qmkst> TYPE qmkst.
    LOOP AT lt_vorgnr INTO DATA(lv_vornr).
      DATA lt_char_res  TYPE TABLE OF bapi2045d2 WITH EMPTY KEY.
      DATA lt_smpl_res  TYPE TABLE OF bapi2045d3 WITH EMPTY KEY.
      DATA lt_singl_res TYPE TABLE OF bapi2045d4 WITH EMPTY KEY.
      DATA lt_return    TYPE TABLE OF bapiret2   WITH EMPTY KEY.
      DATA ls_return    TYPE bapiret2.
      CLEAR: lt_char_res, lt_smpl_res, lt_singl_res, lt_return.
      LOOP AT it_rows INTO DATA(ls_row) WHERE vorgangsnummer = lv_vornr.
        lv_steuerkz = _get_qamv_steuerkz(
          iv_prueflos = iv_prueflos
          iv_vornr    = condense( ls_row-vorgangsnummer )
          iv_merknr   = condense( ls_row-merkmalsnummer )
        ).
        ASSIGN lv_steuerkz TO <fs_qmkst> CASTING.
        ls_qmkst = <fs_qmkst>.
        CASE ls_qmkst-estukz.
          WHEN '+'.  " Einzelwerterfassung → single_results (BAPI2045D4) + char_results zum Abschluss
            DATA(lv_eval) = _get_evaluation(
              iv_prueflos = iv_prueflos
              iv_vornr    = condense( ls_row-vorgangsnummer )
              iv_merknr   = condense( ls_row-merkmalsnummer )
              iv_messwert = ls_row-messwert
            ).
            DATA lv_ep_codegrp TYPE qpac-codegruppe.
            DATA lv_ep_code    TYPE qpac-code.
            CLEAR: lv_ep_codegrp, lv_ep_code.
            DATA(lv_res_no) = _get_next_res_no(
              iv_prueflos = iv_prueflos
              iv_inspoper = CONV vornr( lv_vornr )
              iv_inspchar = CONV qamv-merknr( ls_row-merkmalsnummer )
            ).
            IF ls_row-quanqual = 'QN'.
              " Quantitativ: Messwert in single_results
              APPEND VALUE bapi2045d4(
                insplot    = iv_prueflos
                inspoper   = lv_vornr
                inspchar   = ls_row-merkmalsnummer
                res_no     = lv_res_no
                res_value  = ls_row-messwert
                res_valuat = lv_eval
                inspector  = sy-uname
                insp_date  = sy-datum
                insp_time  = sy-uzeit
                remark     = iv_filename
              ) TO lt_singl_res.
            ELSE.
              " Qualitativ: Code in single_results
              IF ls_row-code_col_idx > 0.
                DATA(lv_ep_pos) = ls_row-code_col_idx - 26.
                DATA(lt_ep_codes) = _get_codes_for_char(
                  iv_prueflos = iv_prueflos
                  iv_vornr    = condense( ls_row-vorgangsnummer )
                  iv_merknr   = condense( ls_row-merkmalsnummer )
                ).
                READ TABLE lt_ep_codes INDEX lv_ep_pos INTO DATA(ls_ep_code).
                IF sy-subrc = 0.
                  " Bewertung aus QPAC-BEWERTUNG ('A'/'R'), Fallback 'A'
                  IF ls_ep_code-bewertung IS NOT INITIAL.
                    lv_eval = ls_ep_code-bewertung.
                  ENDIF.
                  lv_ep_codegrp = ls_ep_code-codegruppe.
                  lv_ep_code    = ls_ep_code-code.
                  APPEND VALUE bapi2045d4(
                    insplot    = iv_prueflos
                    inspoper   = lv_vornr
                    inspchar   = ls_row-merkmalsnummer
                    res_no     = lv_res_no
                    code_grp1  = lv_ep_codegrp
                    code1      = lv_ep_code
                    res_valuat = lv_eval
                    inspector  = sy-uname
                    insp_date  = sy-datum
                    insp_time  = sy-uzeit
                    remark     = iv_filename
                  ) TO lt_singl_res.
                ENDIF.
              ENDIF.
            ENDIF.
            " char_results: Merkmal abschließen (inkl. Code bei QL)
            APPEND VALUE bapi2045d2(
              insplot          = iv_prueflos
              inspoper         = lv_vornr
              inspchar         = ls_row-merkmalsnummer
              code_grp1        = lv_ep_codegrp
              code1            = lv_ep_code
              closed           = 'X'
              evaluation       = lv_eval
              condition_active = 'X'
              res_org          = 'ZA'
              remark           = iv_filename
            ) TO lt_char_res.
          WHEN '='.  " Summenerfassung → sample_results (BAPI2045D3)
            APPEND VALUE bapi2045d3(
              inspchar   = ls_row-merkmalsnummer
              mean_value = ls_row-messwert
              closed     = 'X'
              remark     = iv_filename
            ) TO lt_smpl_res.
          WHEN OTHERS.  " Klassierte Erfassung → char_results (BAPI2045D2) mit Code
            IF ls_row-code_col_idx > 0.
              DATA(lv_code_pos) = ls_row-code_col_idx - 26.
              DATA(lt_codes) = _get_codes_for_char(
                iv_prueflos = iv_prueflos
                iv_vornr    = condense( ls_row-vorgangsnummer )
                iv_merknr   = condense( ls_row-merkmalsnummer )
              ).
              READ TABLE lt_codes INDEX lv_code_pos INTO DATA(ls_code).
              IF sy-subrc = 0.
                APPEND VALUE bapi2045d2(
                  inspchar  = ls_row-merkmalsnummer
                  code_grp1 = ls_code-codegruppe
                  code1     = ls_code-code
                  closed    = 'X'
                  remark    = iv_filename
                ) TO lt_char_res.
              ENDIF.
            ENDIF.
        ENDCASE.
      ENDLOOP.
      DATA lv_inspoper TYPE vornr.
      lv_inspoper = lv_vornr.
      CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
        EXPORTING
          insplot        = iv_prueflos
          inspoper       = lv_inspoper
        IMPORTING
          return         = ls_return
        TABLES
          char_results   = lt_char_res
          sample_results = lt_smpl_res
          single_results = lt_singl_res
          returntable    = lt_return.
      LOOP AT it_rows INTO DATA(ls_rp) WHERE vorgangsnummer = lv_vornr.
        DATA lv_prot_msg  TYPE string.
        DATA lv_prot_stat TYPE c LENGTH 1.
        lv_prot_stat = 'S'.
        CLEAR lv_prot_msg.
        LOOP AT lt_return INTO DATA(ls_ret) WHERE type = 'E' OR type = 'A'.
          lv_prot_stat = 'E'.
          lv_ul_status = 'E'.
          lv_prot_msg  = ls_ret-message.
          EXIT.
        ENDLOOP.
        IF lv_prot_stat = 'S'.
          IF ls_rp-quanqual = 'QN'.
            lv_prot_msg = |Bewertung erfolgreich: { ls_rp-messwert }|.
          ELSE.
            IF ls_rp-code_col_idx > 0.
              DATA(lt_pc) = _get_codes_for_char(
                iv_prueflos = iv_prueflos
                iv_vornr    = condense( ls_rp-vorgangsnummer )
                iv_merknr   = condense( ls_rp-merkmalsnummer )
              ).
              READ TABLE lt_pc INDEX ( ls_rp-code_col_idx - 26 ) INTO DATA(ls_pc).
              IF sy-subrc = 0.
                lv_prot_msg = |Bewertung erfolgreich: { condense( ls_pc-kurztext ) }|.
              ELSE.
                lv_prot_msg = 'Bewertung erfolgreich'.
              ENDIF.
            ELSE.
              lv_prot_msg = 'Bewertung erfolgreich'.
            ENDIF.
          ENDIF.
        ENDIF.
        _write_prot(
          iv_prueflos  = iv_prueflos
          iv_filename  = iv_filename
          iv_excel_row = ls_rp-excel_row
          iv_inspoper  = condense( ls_rp-vorgangsnummer )
          iv_merknr    = condense( ls_rp-merkmalsnummer )
          iv_status    = lv_prot_stat
          iv_msg       = lv_prot_msg
        ).
      ENDLOOP.
    ENDLOOP.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = 'X'.
    _update_status(
      iv_prueflos = iv_prueflos
      iv_status   = lv_ul_status
    ).
  ENDMETHOD.

ENDCLASS.

