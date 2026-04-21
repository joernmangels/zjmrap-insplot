TYPES: BEGIN OF ty_upload_row,
         prueflosnummer TYPE c LENGTH 18,
         vorgangsnummer TYPE c LENGTH 4,
         quanqual       TYPE c LENGTH 2,
         merkmalsnummer TYPE c LENGTH 4,
         messwert       TYPE string,
         ql_kurztext    TYPE string,
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

TYPES ty_prot_status TYPE c LENGTH 1.

CLASS lcl_handler DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read_insplot
      FOR READ
      IMPORTING keys   FOR READ InspLot
      RESULT    result.
    METHODS lock_insplot
      FOR LOCK
      IMPORTING keys FOR LOCK InspLot.
    METHODS read_by_assoc_proteintrag
      FOR READ
      IMPORTING keys_for_read FOR READ InspLot\_ProtEintrag
                  FULL      iv_full_requested
      RESULT    result
                  LINK      association_links.
    METHODS read_by_assoc_merkmale
      FOR READ
      IMPORTING keys_for_read FOR READ InspLot\_Merkmale
                  FULL      iv_full_requested
      RESULT    result
                  LINK      association_links.
    METHODS download
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~download RESULT result.

    METHODS read_proteintrag
      FOR READ
      IMPORTING keys   FOR READ ProtEintrag
      RESULT    result.
    METHODS read_by_assoc_insplot
      FOR READ
      IMPORTING keys_for_read FOR READ ProtEintrag\_InspectionLot
                  FULL      iv_full_requested
      RESULT    result
                  LINK      association_links.
    METHODS read_merkmal
      FOR READ
      IMPORTING keys   FOR READ Merkmal
      RESULT    result.
    METHODS read_by_assoc_insplot_char
      FOR READ
      IMPORTING keys_for_read FOR READ Merkmal\_InspectionLot
                  FULL      iv_full_requested
      RESULT    result
                  LINK      association_links.
    METHODS vormerkliste_leeren
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~vormerkliste_leeren.
    METHODS vormerken_loeschen
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~vormerken_loeschen RESULT result.
    METHODS vormerken
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~vormerken RESULT result.
    METHODS read_by_assoc_dltoken
      FOR READ
      IMPORTING keys_for_read FOR READ InspLot\_DlToken
                FULL          iv_full_requested
      RESULT    result
                LINK          association_links.
    METHODS read_dltoken
      FOR READ
      IMPORTING keys   FOR READ DlToken
      RESULT    result.
    METHODS read_by_assoc_insplot_token
      FOR READ
      IMPORTING keys_for_read FOR READ DlToken\_InspectionLot
                FULL          iv_full_requested
      RESULT    result
                LINK          association_links.
    METHODS uploadResults
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~uploadResults.
    METHODS zuruecksetzen
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~zuruecksetzen.

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
      IMPORTING iv_prueflos       TYPE qals-prueflos
                iv_filename       TYPE string
                iv_excel_row      TYPE i
                iv_inspoper       TYPE string
                iv_merknr         TYPE string
                iv_status         TYPE ty_prot_status
                iv_msg            TYPE string
                iv_radii_code     TYPE qpac-code        OPTIONAL
                iv_radii_codegrp  TYPE qpac-codegruppe  OPTIONAL
                iv_radii_kurztext TYPE qpct-kurztext    OPTIONAL.
    METHODS _update_status
      IMPORTING iv_prueflos TYPE qals-prueflos
                iv_status   TYPE ty_prot_status.
    METHODS _get_ql_code
      IMPORTING iv_prueflos    TYPE qals-prueflos
                iv_vornr       TYPE string
                iv_merknr      TYPE string
                iv_kurztext    TYPE string
      RETURNING VALUE(rs_code) TYPE ty_up_code.
    METHODS _get_radii_code
      IMPORTING iv_prueflos    TYPE qals-prueflos
                iv_vornr       TYPE string
                iv_merknr      TYPE string
                iv_kurztext    TYPE string
      RETURNING VALUE(rs_code) TYPE ty_up_code.
    METHODS _post_results
      IMPORTING iv_prueflos TYPE qals-prueflos
                iv_filename TYPE string
                it_rows     TYPE ty_upload_rows.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD read_insplot.
    IF keys IS INITIAL. RETURN. ENDIF.
    SELECT *
      FROM zjmqmi_i_insplot
      FOR ALL ENTRIES IN @keys
      WHERE InspectionLot = @keys-InspectionLot
      INTO TABLE @DATA(lt_data).
    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<row>).
      APPEND CORRESPONDING #( <row> ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock_insplot.
    " read-only BO, no lock needed
  ENDMETHOD.

  METHOD read_by_assoc_proteintrag.
    IF keys_for_read IS INITIAL. RETURN. ENDIF.
    SELECT prueflos, prot_guid, prot_timestamp, prot_filename, prot_rownr,
           prot_inspoper, prot_insp_char,
           prot_radii_code, prot_radii_codegrp, prot_radii_kurztext,
           prot_status, prot_msg, created_by, created_at
      FROM zjmqmit_prot
      FOR ALL ENTRIES IN @keys_for_read
      WHERE prueflos = @keys_for_read-InspectionLot
      INTO TABLE @DATA(lt_prot).
    LOOP AT lt_prot ASSIGNING FIELD-SYMBOL(<p>).
      APPEND VALUE #(
        source-InspectionLot = <p>-prueflos
        target-InspectionLot = <p>-prueflos
        target-ProtGuid      = <p>-prot_guid
      ) TO association_links.
      APPEND VALUE #(
        InspectionLot            = <p>-prueflos
        ProtGuid                 = <p>-prot_guid
        ProtTimestamp            = <p>-prot_timestamp
        FileName                 = <p>-prot_filename
        RowNumber                = <p>-prot_rownr
        InspectionOperation      = <p>-prot_inspoper
        InspectionCharacteristic = <p>-prot_insp_char
        RadiiCode                = <p>-prot_radii_code
        RadiiCodeGroup           = <p>-prot_radii_codegrp
        RadiiKurztext            = <p>-prot_radii_kurztext
        Status                   = <p>-prot_status
        Message                  = <p>-prot_msg
        CreatedBy                = <p>-created_by
        CreatedAt                = <p>-created_at
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_by_assoc_merkmale.
    IF keys_for_read IS INITIAL. RETURN. ENDIF.
    SELECT *
      FROM zjmqmi_i_insplot_char
      FOR ALL ENTRIES IN @keys_for_read
      WHERE InspectionLot = @keys_for_read-InspectionLot
      INTO TABLE @DATA(lt_char).
    LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<c>).
      APPEND VALUE #(
        source-InspectionLot               = <c>-InspectionLot
        target-InspectionLot               = <c>-InspectionLot
        target-InspPlanOperationInternalID = <c>-InspPlanOperationInternalID
        target-InspectionCharacteristic    = <c>-InspectionCharacteristic
      ) TO association_links.
      APPEND CORRESPONDING #( <c> ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD download.
  ENDMETHOD.

  METHOD read_proteintrag.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE * FROM zjmqmit_prot
        WHERE prueflos  = @<key>-InspectionLot
          AND prot_guid = @<key>-ProtGuid
        INTO @DATA(ls).
      IF sy-subrc = 0.
        APPEND VALUE #(
          InspectionLot            = ls-prueflos
          ProtGuid                 = ls-prot_guid
          ProtTimestamp            = ls-prot_timestamp
          FileName                 = ls-prot_filename
          RowNumber                = ls-prot_rownr
          InspectionOperation      = ls-prot_inspoper
          InspectionCharacteristic = ls-prot_insp_char
          RadiiCode                = ls-prot_radii_code
          RadiiCodeGroup           = ls-prot_radii_codegrp
          RadiiKurztext            = ls-prot_radii_kurztext
          Status                   = ls-prot_status
          Message                  = ls-prot_msg
          CreatedBy                = ls-created_by
          CreatedAt                = ls-created_at
        ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_by_assoc_insplot.
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE * FROM zjmqmi_i_insplot
        WHERE InspectionLot = @<key>-InspectionLot
        INTO @DATA(ls).
      IF sy-subrc = 0.
        APPEND VALUE #(
          source-InspectionLot = <key>-InspectionLot
          source-ProtGuid      = <key>-ProtGuid
          target-InspectionLot = ls-InspectionLot
        ) TO association_links.
        APPEND ls TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_merkmal.
    IF keys IS INITIAL. RETURN. ENDIF.
    SELECT *
      FROM zjmqmi_i_insplot_char
      FOR ALL ENTRIES IN @keys
      WHERE InspectionLot               = @keys-InspectionLot
        AND InspPlanOperationInternalID = @keys-InspPlanOperationInternalID
        AND InspectionCharacteristic    = @keys-InspectionCharacteristic
      INTO TABLE @DATA(lt_data).
    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<char_row>).
      APPEND CORRESPONDING #( <char_row> ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_by_assoc_insplot_char.
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE * FROM zjmqmi_i_insplot
        WHERE InspectionLot = @<key>-InspectionLot
        INTO @DATA(ls).
      IF sy-subrc = 0.
        APPEND VALUE #(
          source-InspectionLot               = <key>-InspectionLot
          source-InspPlanOperationInternalID = <key>-InspPlanOperationInternalID
          source-InspectionCharacteristic    = <key>-InspectionCharacteristic
          target-InspectionLot              = ls-InspectionLot
        ) TO association_links.
        APPEND ls TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD vormerken.
    DATA lv_ts TYPE timestamp.
    GET TIME STAMP FIELD lv_ts.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DATA ls_token TYPE zjmqmit_dl_token.
      ls_token-prueflos   = <key>-InspectionLot.
      ls_token-created_by = sy-uname.
      ls_token-created_at = lv_ts.
      INSERT zjmqmit_dl_token FROM ls_token.
    ENDLOOP.

    SELECT *
      FROM zjmqmi_i_insplot
      FOR ALL ENTRIES IN @keys
      WHERE InspectionLot = @keys-InspectionLot
      INTO TABLE @DATA(lt_data).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key2>).
      READ TABLE lt_data WITH KEY InspectionLot = <key2>-InspectionLot
        ASSIGNING FIELD-SYMBOL(<row>).
      IF sy-subrc = 0.
        DATA(ls_param_vk) = CORRESPONDING zjmqmi_i_insplot( <row> ).
        ls_param_vk-BatchDownloadUrl  = `/sap/bc/zjmqmi/download`.
        ls_param_vk-BatchDownloadText = `DL Watchlist`.
        ls_param_vk-BatchUploadUrl    = `/sap/bc/zjmqmi/upload`.
        ls_param_vk-BatchUploadText   = `UL Watchlist`.
        APPEND VALUE #( %tky = <key2>-%tky %param = ls_param_vk ) TO result.
      ENDIF.
    ENDLOOP.

    reported-insplot = VALUE #( BASE reported-insplot
      ( %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |{ lines( keys ) } { condense( TEXT-001 ) }|
               )
      )
    ).
  ENDMETHOD.

  METHOD vormerkliste_leeren.
    DELETE FROM zjmqmit_dl_token WHERE prueflos IS NOT INITIAL.
  ENDMETHOD.

  METHOD vormerken_loeschen.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DELETE FROM zjmqmit_dl_token
        WHERE prueflos   = @<key>-InspectionLot
          AND created_by = @sy-uname.
    ENDLOOP.

    SELECT *
      FROM zjmqmi_i_insplot
      FOR ALL ENTRIES IN @keys
      WHERE InspectionLot = @keys-InspectionLot
      INTO TABLE @DATA(lt_data).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key2>).
      READ TABLE lt_data WITH KEY InspectionLot = <key2>-InspectionLot
        ASSIGNING FIELD-SYMBOL(<row>).
      IF sy-subrc = 0.
        APPEND VALUE #(
          %tky   = <key2>-%tky
          %param = CORRESPONDING zjmqmi_i_insplot( <row> )
        ) TO result.
      ENDIF.
    ENDLOOP.

    IF keys IS NOT INITIAL.
      reported-insplot = VALUE #( BASE reported-insplot
        ( %tky = keys[ 1 ]-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-success
                   text     = condense( TEXT-003 )
                 )
        )
      ).
    ENDIF.
  ENDMETHOD.

  METHOD read_by_assoc_dltoken.
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key>).
      SELECT prueflos, created_by, created_at
        FROM zjmqmit_dl_token
        WHERE prueflos = @<key>-InspectionLot
        INTO TABLE @DATA(lt_tok).
      LOOP AT lt_tok ASSIGNING FIELD-SYMBOL(<t>).
        APPEND VALUE #(
          source-InspectionLot = <key>-InspectionLot
          target-InspectionLot = <t>-prueflos
          target-CreatedBy     = <t>-created_by
        ) TO association_links.
        APPEND VALUE #(
          InspectionLot = <t>-prueflos
          CreatedBy     = <t>-created_by
          CreatedAt     = <t>-created_at
        ) TO result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_dltoken.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE prueflos, created_by, created_at
        FROM zjmqmit_dl_token
        WHERE prueflos   = @<key>-InspectionLot
          AND created_by = @<key>-CreatedBy
        INTO @DATA(ls_tok).
      IF sy-subrc = 0.
        APPEND VALUE #(
          InspectionLot = ls_tok-prueflos
          CreatedBy     = ls_tok-created_by
          CreatedAt     = ls_tok-created_at
        ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_by_assoc_insplot_token.
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE * FROM zjmqmi_i_insplot
        WHERE InspectionLot = @<key>-InspectionLot
        INTO @DATA(ls_il).
      IF sy-subrc = 0.
        APPEND VALUE #(
          source-InspectionLot = <key>-InspectionLot
          source-CreatedBy     = <key>-CreatedBy
          target-InspectionLot = ls_il-InspectionLot
        ) TO association_links.
        APPEND ls_il TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD _parse_xlsx.
    DATA(lo_zip)   = NEW cl_abap_zip( ).
    DATA lv_xml_raw TYPE xstring.
    DATA lv_xml     TYPE string.
    DATA ls_row     TYPE ty_upload_row.
    DATA lv_row_nr  TYPE i.
    DATA lv_rest    TYPE string.
    DATA lv_rowxml  TYPE string.
    DATA lv_rownum  TYPE string.

    lo_zip->load( EXPORTING zip    = iv_xstring
                  EXCEPTIONS others = 1 ).
    CHECK sy-subrc = 0.

    lo_zip->get( EXPORTING  name    = 'xl/worksheets/sheet1.xml'
                 IMPORTING  content = lv_xml_raw
                 EXCEPTIONS others  = 1 ).
    CHECK sy-subrc = 0.

    lv_xml  = cl_abap_codepage=>convert_from( source   = lv_xml_raw
                                              codepage = 'UTF-8' ).
    lv_rest = lv_xml.
    FIND FIRST OCCURRENCE OF REGEX `<row r="(\d+)"` IN lv_rest
      SUBMATCHES lv_rownum.

    WHILE sy-subrc = 0.
      FIND FIRST OCCURRENCE OF `</row>` IN lv_rest MATCH OFFSET DATA(lv_end).
      lv_rowxml = substring( val = lv_rest off = 0 len = lv_end ).
      lv_rest   = substring( val = lv_rest off = lv_end + 6 ).

      IF lv_rownum = '1'.
        FIND FIRST OCCURRENCE OF REGEX `<row r="(\d+)"` IN lv_rest
          SUBMATCHES lv_rownum.
        CONTINUE.
      ENDIF.

      lv_row_nr = lv_rownum.
      CLEAR ls_row.
      ls_row-excel_row = lv_row_nr.

      DATA lv_cell_rest TYPE string.
      DATA lv_col_let   TYPE string.
      DATA lv_cell_val  TYPE string.
      DATA lv_col_idx   TYPE i.
      DATA lv_t_start   TYPE i.
      DATA lv_t_end     TYPE i.
      DATA lv_t_off     TYPE i.
      DATA lv_t_len     TYPE i.
      DATA lv_c_end     TYPE i.
      lv_cell_rest = lv_rowxml.

      FIND FIRST OCCURRENCE OF REGEX `<c r="([A-Z]+)\d+"` IN lv_cell_rest
        SUBMATCHES lv_col_let.

      WHILE sy-subrc = 0.
        FIND FIRST OCCURRENCE OF `<t>` IN lv_cell_rest MATCH OFFSET lv_t_start.
        FIND FIRST OCCURRENCE OF `</t>` IN lv_cell_rest MATCH OFFSET lv_t_end.
        IF sy-subrc = 0.
          lv_t_off = lv_t_start + 3.
          lv_t_len = lv_t_end - lv_t_off.
          IF lv_t_len > 0.
            lv_cell_val = substring( val = lv_cell_rest off = lv_t_off len = lv_t_len ).
          ELSE.
            CLEAR lv_cell_val.
          ENDIF.
        ELSE.
          CLEAR lv_cell_val.
        ENDIF.

        lv_col_idx = _col_letter_to_idx( lv_col_let ).
        CASE lv_col_idx.
          WHEN 1.  ls_row-prueflosnummer = condense( lv_cell_val ).
          WHEN 10. ls_row-vorgangsnummer = condense( lv_cell_val ).
          WHEN 15. ls_row-merkmalsnummer = condense( lv_cell_val ).
          WHEN 26.
            IF condense( lv_cell_val ) <> ``.
              ls_row-radii_1 = condense( lv_cell_val ).
            ENDIF.
          WHEN 27.
            IF condense( lv_cell_val ) <> ``.
              ls_row-radii_2 = condense( lv_cell_val ).
            ENDIF.
          WHEN 28. ls_row-quanqual = condense( lv_cell_val ).
          WHEN 29.
            IF condense( lv_cell_val ) <> ``.
              IF ls_row-quanqual = 'QN'.
                ls_row-messwert = condense( lv_cell_val ).
              ELSE.
                ls_row-ql_kurztext = condense( lv_cell_val ).
              ENDIF.
            ENDIF.
          WHEN OTHERS.
        ENDCASE.

        FIND FIRST OCCURRENCE OF `</c>` IN lv_cell_rest MATCH OFFSET lv_c_end.
        lv_cell_rest = substring( val = lv_cell_rest off = lv_c_end + 4 ).
        FIND FIRST OCCURRENCE OF REGEX `<c r="([A-Z]+)\d+"` IN lv_cell_rest
          SUBMATCHES lv_col_let.
      ENDWHILE.

      IF ls_row-prueflosnummer IS NOT INITIAL AND ls_row-merkmalsnummer IS NOT INITIAL.
        APPEND ls_row TO rt_rows.
      ENDIF.

      FIND FIRST OCCURRENCE OF REGEX `<row r="(\d+)"` IN lv_rest
        SUBMATCHES lv_rownum.
    ENDWHILE.
  ENDMETHOD.

  METHOD _get_codes_for_char.
    SELECT SINGLE InspPlanOperationInternalID
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(lv_vorglfnr).
    CHECK sy-subrc = 0.

    SELECT SINGLE katalgart1, auswmenge1, auswmgwrk1
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @lv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @DATA(ls_qamv).
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
    DATA(lv_guid) = CAST if_system_uuid( cl_uuid_factory=>create_system_uuid( ) )->create_uuid_c32( ).
    DATA ls_prot TYPE zjmqmit_prot.
    GET TIME STAMP FIELD ls_prot-prot_timestamp.
    ls_prot-prueflos       = iv_prueflos.
    ls_prot-prot_guid      = lv_guid.
    ls_prot-prot_filename  = iv_filename.
    ls_prot-prot_rownr     = iv_excel_row.
    ls_prot-prot_inspoper      = iv_inspoper.
    ls_prot-prot_insp_char     = iv_merknr.
    ls_prot-prot_radii_code     = iv_radii_code.
    ls_prot-prot_radii_codegrp  = iv_radii_codegrp.
    ls_prot-prot_radii_kurztext = iv_radii_kurztext.
    ls_prot-prot_status         = iv_status.
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
    SELECT SINGLE InspPlanOperationInternalID
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(lv_vorglfnr).
    CHECK sy-subrc = 0.
    SELECT SINGLE steuerkz
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @lv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @rv_steuerkz.
  ENDMETHOD.

  METHOD _get_evaluation.
    rv_result = 'A'.
    CHECK iv_messwert IS NOT INITIAL.
    SELECT SINGLE InspSpecUpperLimit, InspSpecLowerLimit
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(ls_lim).
    CHECK sy-subrc = 0.
    DATA(lv_val_str) = iv_messwert.
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

  METHOD _get_ql_code.
    SELECT SINGLE InspPlanOperationInternalID
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(lv_vorglfnr).
    CHECK sy-subrc = 0.
    SELECT SINGLE katalgart1, auswmenge1, auswmgwrk1
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @lv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @DATA(ls_qamv).
    CHECK sy-subrc = 0
      AND ls_qamv-katalgart1 IS NOT INITIAL
      AND ls_qamv-auswmenge1 IS NOT INITIAL.
    SELECT SINGLE qpac~codegruppe, qpac~code, qpac~bewertung
      FROM qpac
      INNER JOIN qpct
        ON  qpct~katalogart = qpac~katalogart
        AND qpct~codegruppe = qpac~codegruppe
        AND qpct~code       = qpac~code
        AND qpct~sprache    = @sy-langu
      WHERE qpac~katalogart = @ls_qamv-katalgart1
        AND qpac~werks      = @ls_qamv-auswmgwrk1
        AND qpac~auswahlmge = @ls_qamv-auswmenge1
        AND qpct~kurztext   = @iv_kurztext
      INTO @DATA(ls_match).
    CHECK sy-subrc = 0.
    rs_code-code       = ls_match-code.
    rs_code-codegruppe = ls_match-codegruppe.
    rs_code-bewertung  = ls_match-bewertung.
  ENDMETHOD.


  METHOD _get_radii_code.
    SELECT SINGLE InspPlanOperationInternalID
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(lv_vorglfnr).
    CHECK sy-subrc = 0.
    SELECT SINGLE katalgart2, auswmenge2
      FROM qamv
      WHERE prueflos = @iv_prueflos
        AND vorglfnr = @lv_vorglfnr
        AND merknr   = @iv_merknr
      INTO @DATA(ls_qamv).
    CHECK sy-subrc = 0
      AND ls_qamv-katalgart2 = 'E'
      AND ls_qamv-auswmenge2 IS NOT INITIAL.
    SELECT SINGLE code, codegruppe, kurztext
      FROM qpct
      WHERE katalogart = @ls_qamv-katalgart2
        AND codegruppe = @ls_qamv-auswmenge2
        AND sprache    = @sy-langu
        AND kurztext   = @iv_kurztext
      INTO @DATA(ls_pct).
    CHECK sy-subrc = 0.
    rs_code-code       = ls_pct-code.
    rs_code-codegruppe = ls_pct-codegruppe.
    rs_code-kurztext   = ls_pct-kurztext.
  ENDMETHOD.


  METHOD _post_results.
    DATA lt_vorgnr    TYPE TABLE OF string WITH EMPTY KEY.
    DATA lt_char_res  TYPE TABLE OF bapi2045d2 WITH EMPTY KEY.
    DATA lt_smpl_res  TYPE TABLE OF bapi2045d3 WITH EMPTY KEY.
    DATA lt_singl_res TYPE TABLE OF bapi2045d4 WITH EMPTY KEY.
    DATA lt_return    TYPE TABLE OF bapiret2   WITH EMPTY KEY.
    DATA ls_return    TYPE bapiret2.
    DATA lv_ep_codegrp TYPE qpac-codegruppe.
    DATA lv_ep_code    TYPE qpac-code.
    DATA lv_prot_msg   TYPE string.
    DATA lv_prot_stat  TYPE ty_prot_status.
    FIELD-SYMBOLS <steuerkz> TYPE qmkst.

    LOOP AT it_rows INTO DATA(ls_r).
      APPEND condense( ls_r-vorgangsnummer ) TO lt_vorgnr.
    ENDLOOP.
    SORT lt_vorgnr.
    DELETE ADJACENT DUPLICATES FROM lt_vorgnr.

    DATA lv_ul_status TYPE ty_prot_status.
    lv_ul_status = 'S'.

    LOOP AT lt_vorgnr INTO DATA(lv_vornr).
      CLEAR: lt_char_res, lt_smpl_res, lt_singl_res, lt_return, ls_return.

      DATA lv_radii_kurztext TYPE string.
      DATA ls_radii_code     TYPE ty_up_code.
      LOOP AT it_rows INTO DATA(ls_row) WHERE vorgangsnummer = lv_vornr.
        DATA(lv_vornr_str)  = condense( ls_row-vorgangsnummer ).
        DATA(lv_merknr_str) = condense( ls_row-merkmalsnummer ).

        CLEAR: lv_radii_kurztext, ls_radii_code.
        IF ls_row-radii_1 IS NOT INITIAL AND ls_row-radii_2 IS INITIAL.
          lv_radii_kurztext = ls_row-radii_1.
        ELSEIF ls_row-radii_2 IS NOT INITIAL AND ls_row-radii_1 IS INITIAL.
          lv_radii_kurztext = ls_row-radii_2.
        ENDIF.
        IF lv_radii_kurztext IS NOT INITIAL.
          ls_radii_code = _get_radii_code(
            iv_prueflos = iv_prueflos
            iv_vornr    = lv_vornr_str
            iv_merknr   = lv_merknr_str
            iv_kurztext = lv_radii_kurztext
          ).
        ENDIF.

        DATA(lv_steuerkz) = _get_qamv_steuerkz(
          iv_prueflos = iv_prueflos
          iv_vornr    = lv_vornr_str
          iv_merknr   = lv_merknr_str
        ).
        ASSIGN lv_steuerkz TO <steuerkz> CASTING.
        CLEAR: lv_ep_codegrp, lv_ep_code.

        CASE <steuerkz>-estukz.
          WHEN '+'.
            DATA(lv_eval) = _get_evaluation(
              iv_prueflos = iv_prueflos
              iv_vornr    = lv_vornr_str
              iv_merknr   = lv_merknr_str
              iv_messwert = ls_row-messwert
            ).
            DATA(lv_res_no) = _get_next_res_no(
              iv_prueflos = iv_prueflos
              iv_inspoper = CONV vornr( lv_vornr )
              iv_inspchar = CONV qamv-merknr( ls_row-merkmalsnummer )
            ).
            IF ls_row-quanqual = 'QN'.
              APPEND VALUE bapi2045d4(
                insplot    = iv_prueflos
                inspoper   = lv_vornr
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
              ) TO lt_singl_res.
            ELSEIF ls_row-ql_kurztext IS NOT INITIAL.
              DATA(ls_ep_code) = _get_ql_code(
                iv_prueflos = iv_prueflos
                iv_vornr    = lv_vornr_str
                iv_merknr   = lv_merknr_str
                iv_kurztext = ls_row-ql_kurztext
              ).
              IF ls_ep_code-code IS NOT INITIAL.
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
                  code_grp2  = ls_radii_code-codegruppe
                  code2      = ls_radii_code-code
                  res_valuat = lv_eval
                  inspector  = sy-uname
                  insp_date  = sy-datum
                  insp_time  = sy-uzeit
                  remark     = iv_filename
                ) TO lt_singl_res.
              ENDIF.
            ENDIF.
            APPEND VALUE bapi2045d2(
              insplot          = iv_prueflos
              inspoper         = lv_vornr
              inspchar         = ls_row-merkmalsnummer
              code_grp1        = lv_ep_codegrp
              code1            = lv_ep_code
              code_grp2        = ls_radii_code-codegruppe
              code2            = ls_radii_code-code
              closed           = 'X'
              evaluation       = lv_eval
              condition_active = 'X'
              res_org          = 'ZA'
              remark           = iv_filename
            ) TO lt_char_res.

          WHEN '='.
            APPEND VALUE bapi2045d3(
              inspchar   = ls_row-merkmalsnummer
              mean_value = ls_row-messwert
              closed     = 'X'
              remark     = iv_filename
            ) TO lt_smpl_res.

          WHEN OTHERS.
            IF ls_row-ql_kurztext IS NOT INITIAL.
              DATA(ls_oth_code) = _get_ql_code(
                iv_prueflos = iv_prueflos
                iv_vornr    = lv_vornr_str
                iv_merknr   = lv_merknr_str
                iv_kurztext = ls_row-ql_kurztext
              ).
              IF ls_oth_code-code IS NOT INITIAL.
                APPEND VALUE bapi2045d2(
                  inspchar  = ls_row-merkmalsnummer
                  code_grp1 = ls_oth_code-codegruppe
                  code1     = ls_oth_code-code
                  code_grp2 = ls_radii_code-codegruppe
                  code2     = ls_radii_code-code
                  closed    = 'X'
                  remark    = iv_filename
                ) TO lt_char_res.
              ENDIF.
            ENDIF.
        ENDCASE.
      ENDLOOP.

      DATA(lv_inspoper) = CONV vornr( lv_vornr ).
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

      DATA lv_ri_kt   TYPE string.
      DATA ls_ri_code TYPE ty_up_code.
      LOOP AT it_rows INTO DATA(ls_rp) WHERE vorgangsnummer = lv_vornr.
        CLEAR: lv_ri_kt, ls_ri_code.
        IF ls_rp-radii_1 IS NOT INITIAL AND ls_rp-radii_2 IS INITIAL.
          lv_ri_kt = ls_rp-radii_1.
        ELSEIF ls_rp-radii_2 IS NOT INITIAL AND ls_rp-radii_1 IS INITIAL.
          lv_ri_kt = ls_rp-radii_2.
        ENDIF.
        IF lv_ri_kt IS NOT INITIAL.
          ls_ri_code = _get_radii_code(
            iv_prueflos = iv_prueflos
            iv_vornr    = condense( ls_rp-vorgangsnummer )
            iv_merknr   = condense( ls_rp-merkmalsnummer )
            iv_kurztext = lv_ri_kt
          ).
        ENDIF.
        lv_prot_stat = 'S'.
        CLEAR lv_prot_msg.
        LOOP AT lt_return INTO DATA(ls_ret) WHERE type = 'E' OR type = 'A'.
          lv_prot_stat = 'E'.
          lv_ul_status = 'E'.
          lv_prot_msg  = ls_ret-message.
          EXIT.
        ENDLOOP.
        IF lv_prot_stat = 'S'.
          DATA(lv_rp_vornr) = condense( ls_rp-vorgangsnummer ).
          DATA(lv_rp_merknr) = condense( ls_rp-merkmalsnummer ).
          IF ls_rp-quanqual = 'QN'.
            DATA(lv_pm_eval) = _get_evaluation(
              iv_prueflos = iv_prueflos
              iv_vornr    = lv_rp_vornr
              iv_merknr   = lv_rp_merknr
              iv_messwert = ls_rp-messwert
            ).
            lv_prot_msg = |{ condense( TEXT-005 ) } { lv_pm_eval } - { ls_rp-messwert }|.
          ELSE.
            IF ls_rp-ql_kurztext IS NOT INITIAL.
              DATA(ls_pm_code) = _get_ql_code(
                iv_prueflos = iv_prueflos
                iv_vornr    = lv_rp_vornr
                iv_merknr   = lv_rp_merknr
                iv_kurztext = ls_rp-ql_kurztext
              ).
              IF ls_pm_code-code IS NOT INITIAL.
                lv_prot_msg = |{ condense( TEXT-005 ) } { ls_pm_code-bewertung } - { ls_rp-ql_kurztext }|.
              ELSE.
                lv_prot_msg = TEXT-006.
              ENDIF.
            ELSE.
              lv_prot_msg = TEXT-006.
            ENDIF.
          ENDIF.
        ENDIF.
        _write_prot(
          iv_prueflos       = iv_prueflos
          iv_filename       = iv_filename
          iv_excel_row      = ls_rp-excel_row
          iv_inspoper       = condense( ls_rp-vorgangsnummer )
          iv_merknr         = condense( ls_rp-merkmalsnummer )
          iv_status         = lv_prot_stat
          iv_msg            = lv_prot_msg
          iv_radii_code     = ls_ri_code-code
          iv_radii_codegrp  = ls_ri_code-codegruppe
          iv_radii_kurztext = ls_ri_code-kurztext
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

  METHOD uploadResults.
    CHECK keys IS NOT INITIAL.
    DATA(ls_param)   = keys[ 1 ]-%param.
    DATA(lv_content) = ls_param-FileContent.
    DATA(lv_fname)   = CONV string( condense( ls_param-FileName ) ).
    CHECK lv_content IS NOT INITIAL.

    DATA(lt_rows) = _parse_xlsx( lv_content ).
    CHECK lt_rows IS NOT INITIAL.

    DATA lt_lots TYPE TABLE OF qals-prueflos WITH EMPTY KEY.
    LOOP AT lt_rows INTO DATA(ls_r).
      APPEND CONV qals-prueflos( condense( ls_r-prueflosnummer ) ) TO lt_lots.
    ENDLOOP.
    SORT lt_lots.
    DELETE ADJACENT DUPLICATES FROM lt_lots.

    LOOP AT lt_lots INTO DATA(lv_lot).
      DATA(lt_lot_rows) = VALUE ty_upload_rows(
        FOR r IN lt_rows WHERE ( prueflosnummer = lv_lot ) ( r )
      ).
      _post_results(
        iv_prueflos = lv_lot
        iv_filename = lv_fname
        it_rows     = lt_lot_rows
      ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zuruecksetzen.
    DATA lv_count TYPE i.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      IF <key>-%param-Bestaetigen = abap_true.
        DELETE FROM zjmqmit_prot     WHERE prueflos = @<key>-InspectionLot.
        DELETE FROM zjmqmit_status   WHERE prueflos = @<key>-InspectionLot.
        DELETE FROM zjmqmit_dl_token WHERE prueflos = @<key>-InspectionLot.
        lv_count += 1.
      ENDIF.
    ENDLOOP.
    IF lv_count > 0.
      reported-insplot = VALUE #( BASE reported-insplot
        ( %tky = keys[ 1 ]-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-success
                   text     = |{ lv_count } { condense( TEXT-004 ) }|
                 )
        )
      ).
    ENDIF.
  ENDMETHOD.

  METHOD _col_letter_to_idx.
    CONSTANTS lc_alpha TYPE c LENGTH 26 VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
    DATA(lv_upper) = to_upper( iv_col ).
    DATA lv_pos    TYPE i.
    DATA lv_off    TYPE i.
    rv_idx = 0.
    DO strlen( lv_upper ) TIMES.
      lv_off = sy-index - 1.
      FIND lv_upper+lv_off(1) IN lc_alpha MATCH OFFSET lv_pos.
      rv_idx = rv_idx * 26 + lv_pos + 1.
    ENDDO.
  ENDMETHOD.

ENDCLASS.
