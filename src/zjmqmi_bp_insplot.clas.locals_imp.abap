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
*    METHODS get_instance_features FOR INSTANCE FEATURES
*      IMPORTING keys REQUEST requested_features FOR insplot RESULT result.
    METHODS vormerkliste_leeren
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~vormerkliste_leeren.
    METHODS vormerken_loeschen
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~vormerken_loeschen.
    METHODS vormerken
      FOR MODIFY
      IMPORTING keys FOR ACTION InspLot~vormerken.
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
      IMPORTING iv_xstring      TYPE xstring
      RETURNING VALUE(rt_rows)  TYPE ty_upload_rows.

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

CLASS lcl_handler IMPLEMENTATION.

  METHOD read_insplot.
    IF keys IS INITIAL. RETURN. ENDIF.
    SELECT *
      FROM zjmqmi_i_insplot
      FOR ALL ENTRIES IN @keys
      WHERE InspectionLot = @keys-InspectionLot
      INTO TABLE @DATA(lt_data).
    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls>).
      APPEND CORRESPONDING #( <ls> ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock_insplot.
    " read-only BO, no lock needed
  ENDMETHOD.

  METHOD read_by_assoc_proteintrag.
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key>).
      SELECT * FROM zjmqmit_prot
        WHERE prueflos = @<key>-InspectionLot
        INTO TABLE @DATA(lt_prot).
      LOOP AT lt_prot ASSIGNING FIELD-SYMBOL(<p>).
        APPEND VALUE #(
          source-InspectionLot = <key>-InspectionLot
          target-InspectionLot = <p>-prueflos
          target-ProtGuid      = <p>-prot_guid
        ) TO association_links.
        APPEND VALUE #(
          InspectionLot           = <p>-prueflos
          ProtGuid                = <p>-prot_guid
          ProtTimestamp           = <p>-prot_timestamp
          FileName                = <p>-prot_filename
          RowNumber               = <p>-prot_rownr
          InspectionOperation     = <p>-prot_inspoper
          InspectionCharacteristic = <p>-prot_insp_char
          Status                  = <p>-prot_status
          Message                 = <p>-prot_msg
          CreatedBy               = <p>-created_by
          CreatedAt               = <p>-created_at
        ) TO result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_by_assoc_merkmale.
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key>).
      SELECT * FROM zjmqmi_i_insplot_char
        WHERE InspectionLot = @<key>-InspectionLot
        INTO TABLE @DATA(lt_char).
      LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<c>).
        APPEND VALUE #(
          source-InspectionLot              = <key>-InspectionLot
          target-InspectionLot              = <c>-InspectionLot
          target-InspPlanOperationInternalID = <c>-InspPlanOperationInternalID
          target-InspectionCharacteristic    = <c>-InspectionCharacteristic
        ) TO association_links.
        APPEND CORRESPONDING #( <c> ) TO result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

*  METHOD download1.
*    CHECK keys IS NOT INITIAL.
*
*    DATA(ls_first)    = keys[ 1 ].
*    DATA(lv_path)     = condense( ls_first-%param-DownloadPath ).
*    DATA(lv_filename) = condense( ls_first-%param-DownloadFileName ).
*
*    " Trailing-Separator sicherstellen
*    DATA(lv_sep)  = COND #( WHEN lv_path CS '\' THEN '\' ELSE '/' ).
*    DATA(lv_plen) = strlen( lv_path ).
*    IF lv_plen > 0 AND substring( val = lv_path off = lv_plen - 1 len = 1 ) <> lv_sep.
*      lv_path = lv_path && lv_sep.
*    ENDIF.
*    DATA(lv_filepath) = |{ lv_path }{ lv_filename }.xls|.
*
*    " SpreadsheetML XML aufbauen (Excel öffnet dieses Format direkt)
*    DATA(lv_xml) =
*      |<?xml version="1.0" encoding="UTF-8"?>| &&
*      |<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"| &&
*      | xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">| &&
*      |<Worksheet ss:Name="Pruefmerkmale"><Table>| &&
*      |<Row>| &&
*      |<Cell><Data ss:Type="String">Prueflosnummer</Data></Cell>| &&
*      |<Cell><Data ss:Type="String">Vorgangsnummer</Data></Cell>| &&
*      |<Cell><Data ss:Type="String">Merkmalsnummer</Data></Cell>| &&
*      |<Cell><Data ss:Type="String">Kurztext</Data></Cell>| &&
*      |<Cell><Data ss:Type="String">Pruefergebnis</Data></Cell>| &&
*      |</Row>|.
*
*    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
*      SELECT InspectionLot,
*             InspectionOperation,
*             InspectionCharacteristic,
*             InspectionCharacteristicText
*        FROM zjmqmi_i_insplot_char
*        WHERE InspectionLot = @<key>-InspectionLot
*        ORDER BY InspectionOperation, InspectionCharacteristic
*        INTO TABLE @DATA(lt_char).
*
*      LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<c>).
*        lv_xml = lv_xml &&
*          |<Row>| &&
*          |<Cell><Data ss:Type="String">{ condense( <c>-InspectionLot ) }</Data></Cell>| &&
*          |<Cell><Data ss:Type="String">{ condense( <c>-InspectionOperation ) }</Data></Cell>| &&
*          |<Cell><Data ss:Type="String">{ condense( <c>-InspectionCharacteristic ) }</Data></Cell>| &&
*          |<Cell><Data ss:Type="String">{ <c>-InspectionCharacteristicText }</Data></Cell>| &&
*          |<Cell><Data ss:Type="String"></Data></Cell>| &&
*          |</Row>|.
*      ENDLOOP.
*    ENDLOOP.
*
*    lv_xml = lv_xml && |</Table></Worksheet></Workbook>|.
*
*    " In XSTRING konvertieren und auf Applikationsserver speichern
*    DATA(lv_xstring) = cl_abap_codepage=>convert_to( source = lv_xml codepage = 'UTF-8' ).
*
**    OPEN DATASET lv_filepath FOR OUTPUT IN BINARY MODE.
**    IF sy-subrc = 0.
**      TRANSFER lv_xstring TO lv_filepath.
**      CLOSE DATASET lv_filepath.
**    ENDIF.
*
*
*    DATA: lt_binary TYPE solix_tab,
*          lv_size   TYPE i.
*
*    " 1. Beispiel: XSTRING befüllen (aus einer Quelle wie Smartform/Adobe Form)
*    " lv_xstring = ...
*
*    " 2. XSTRING in binäre Tabelle konvertieren (erforderlich für GUI_DOWNLOAD)
*    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
*      EXPORTING
*        buffer        = lv_xstring
*      IMPORTING
*        output_length = lv_size
*      TABLES
*        binary_tab    = lt_binary.
*
*    " 3. Auf Desktop herunterladen
*    cl_gui_frontend_services=>gui_download(
*      EXPORTING
*        filename                = lv_filepath
*        filetype                = 'BIN' " WICHTIG: Für Binärdateien
*        bin_filesize            = lv_size
*      CHANGING
*        data_tab                = lt_binary
*      EXCEPTIONS
*        OTHERS                  = 1
*    ).
*
*




  " Ergebnis zurückgeben
*    LOOP AT keys ASSIGNING FIELD-SYMBOL(<k>).
*      APPEND VALUE #( %tky = <k>-%tky ) TO result.
*    ENDLOOP.
*     result = VALUE #( FOR key IN keys ( %tky   = key-%tky ) ).
*  ENDMETHOD.
*  METHOD download.
*    CHECK keys IS NOT INITIAL.
*
*    TYPES: BEGIN OF ty_row,
*             prueflosnummer TYPE c LENGTH 18,
*             vorgangsnummer TYPE c LENGTH 4,
*             merkmalsnummer TYPE c LENGTH 4,
*             kurztext       TYPE c LENGTH 40,
*             pruefergebnis  TYPE c LENGTH 1,
*           END OF ty_row.
*
*    DATA(ls_first)    = keys[ 1 ].
*    DATA(lv_filename) = condense( ls_first-%param-DownloadFileName ).
*    IF lv_filename IS INITIAL.
*      lv_filename = 'PrueflosMerkmale'.
*    ENDIF.
*
*    " Daten in interne Tabelle laden (1. Zeile = Überschriften)
*    DATA lt_data TYPE TABLE OF ty_row WITH EMPTY KEY.
*
*    APPEND VALUE ty_row(
*      prueflosnummer = 'Prueflosnummer'
*      vorgangsnummer = 'Vorgangsnummer'
*      merkmalsnummer = 'Merkmalsnummer'
*      kurztext       = 'Kurztext'
*      pruefergebnis  = ' '
*    ) TO lt_data.
*
*    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
*      SELECT InspectionLot,
*             InspectionOperation,
*             InspectionCharacteristic,
*             InspectionCharacteristicText
*        FROM zjmqmi_i_insplot_char
*        WHERE InspectionLot = @<key>-InspectionLot
*        ORDER BY InspectionOperation, InspectionCharacteristic
*        INTO TABLE @DATA(lt_char).
*
*      LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<c>).
*        APPEND VALUE ty_row(
*          prueflosnummer = <c>-InspectionLot
*          vorgangsnummer = <c>-InspectionOperation
*          merkmalsnummer = <c>-InspectionCharacteristic
*          kurztext       = <c>-InspectionCharacteristicText
*          pruefergebnis  = ' '
*        ) TO lt_data.
*      ENDLOOP.
*    ENDLOOP.
*
*    " XLSX mit xco_cp_xlsx erzeugen
*    DATA(lo_write_access) = xco_cp_xlsx=>document->empty( )->write_access( ).
*    DATA(lo_worksheet)    = lo_write_access->get_workbook(
*        )->worksheet->at_position( 1 ).
*
*    DATA(lo_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
*        )->from_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )
*        )->to_column(   xco_cp_xlsx=>coordinate->for_alphabetic_value( 'E' )
*        )->from_row(    xco_cp_xlsx=>coordinate->for_numeric_value( 1 )
*        )->get_pattern( ).
*
*    lo_worksheet->select( lo_pattern
*        )->row_stream(
*        )->operation->write_from( REF #( lt_data )
*        )->execute( ).
*
*    DATA(lv_file_content) = lo_write_access->get_file_content( ).
*
*    DATA(lv_full_name) = |{ lv_filename }.xlsx|.
*
*    " Ergebnis zurückgeben – Fiori löst Browser-Download aus (#ATTACHMENT)
*    LOOP AT keys ASSIGNING FIELD-SYMBOL(<k>).
*      APPEND VALUE #(
*        %tky               = <k>-%tky
*        %param-FileContent = lv_file_content
*        %param-MimeType    = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
*        %param-FileName    = lv_full_name
*      ) TO result.
*    ENDLOOP.
*
*    " Success-Toast anzeigen
*    reported-insplot = VALUE #( BASE reported-insplot
*      ( %tky = keys[ 1 ]-%tky
*        %msg = new_message_with_text(
*                 severity = if_abap_behv_message=>severity-success
*                 text     = |Datei '{ lv_full_name }' wurde gespeichert!|
*               )
*      )
*    ).
*  ENDMETHOD.

  METHOD download.
*    CHECK keys IS NOT INITIAL.
*
*    TYPES: BEGIN OF ty_row,
*             prueflosnummer TYPE c LENGTH 18,
*             vorgangsnummer TYPE c LENGTH 4,
*             merkmalsnummer TYPE c LENGTH 4,
*             kurztext       TYPE c LENGTH 40,
*             pruefergebnis  TYPE c LENGTH 1,
*           END OF ty_row.
*
*    DATA(lv_filename) = condense( keys[ 1 ]-%param-DownloadFileName ).
*    IF lv_filename IS INITIAL. lv_filename = 'Prueflose'. ENDIF.
*
*    " Daten ALLER ausgewaehlten Prueflose sammeln
*    DATA lt_data TYPE TABLE OF ty_row WITH EMPTY KEY.
*    APPEND VALUE ty_row(
*      prueflosnummer = 'Prueflosnummer'  vorgangsnummer = 'Vorgangsnummer'
*      merkmalsnummer = 'Merkmalsnummer'  kurztext       = 'Kurztext'
*      pruefergebnis  = ' '
*    ) TO lt_data.
*
*    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
*      SELECT InspectionLot, InspectionOperation,
*             InspectionCharacteristic, InspectionCharacteristicText
*        FROM zjmqmi_i_insplot_char
*        WHERE InspectionLot = @<key>-InspectionLot
*        ORDER BY InspectionOperation, InspectionCharacteristic
*        INTO TABLE @DATA(lt_char).
*      LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<c>).
*        APPEND VALUE ty_row(
*          prueflosnummer = <c>-InspectionLot
*          vorgangsnummer = <c>-InspectionOperation
*          merkmalsnummer = <c>-InspectionCharacteristic
*          kurztext       = <c>-InspectionCharacteristicText
*          pruefergebnis  = ' '
*        ) TO lt_data.
*      ENDLOOP.
*    ENDLOOP.
*
*    " XLSX erzeugen
*    DATA(lo_wa)  = xco_cp_xlsx=>document->empty( )->write_access( ).
*    DATA(lo_ws)  = lo_wa->get_workbook( )->worksheet->at_position( 1 ).
*    DATA(lo_pat) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
*        )->from_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )
*        )->to_column(   xco_cp_xlsx=>coordinate->for_alphabetic_value( 'E' )
*        )->from_row(    xco_cp_xlsx=>coordinate->for_numeric_value( 1 )
*        )->get_pattern( ).
*    lo_ws->select( lo_pat )->row_stream( )->operation->write_from( REF #( lt_data ) )->execute( ).
*    DATA(lv_content) = lo_wa->get_file_content( ).
*
*    " Token in DB speichern
*    DATA(lv_token) = CAST if_system_uuid(
*        cl_uuid_factory=>create_system_uuid( ) )->create_uuid_c32( ).
*    DATA(lv_full_name) = |{ lv_filename }.xlsx|.
*    GET TIME STAMP FIELD DATA(lv_ts).
*    DATA ls_tok TYPE zjmqmit_dl_token.
*    ls_tok-token        = lv_token.
*    ls_tok-created_at   = lv_ts.
*    ls_tok-created_by   = sy-uname.
*    ls_tok-filename     = lv_full_name.
*    ls_tok-file_content = lv_content.
*    INSERT zjmqmit_dl_token FROM ls_tok.
*
*    " Download-URL als Ergebnis
*    DATA(lv_url) = |/sap/bc/zjmqmi/download?token={ lv_token }|.
*    APPEND VALUE #(
*      %tky               = keys[ 1 ]-%tky
*      %param-DownloadUrl = lv_url
*      %param-FileName    = lv_full_name
*    ) TO result.
*
*    reported-insplot = VALUE #( BASE reported-insplot
*      ( %tky = keys[ 1 ]-%tky
*        %msg = new_message_with_text(
*                 severity = if_abap_behv_message=>severity-success
*                 text     = |{ lines( keys ) } Prüflos(e) bereit – URL: { lv_url }|
*               )
*      )
*    ).

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
          Status                   = ls-prot_status
          Message                  = ls-prot_msg
          CreatedBy                = ls-created_by
          CreatedAt                = ls-created_at ) TO result.
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
      WHERE InspectionLot              = @keys-InspectionLot
        AND InspPlanOperationInternalID = @keys-InspPlanOperationInternalID
        AND InspectionCharacteristic    = @keys-InspectionCharacteristic
      INTO TABLE @DATA(lt_data).
    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<lm>).
      APPEND CORRESPONDING #( <lm> ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_by_assoc_insplot_char.
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE * FROM zjmqmi_i_insplot
        WHERE InspectionLot = @<key>-InspectionLot
        INTO @DATA(ls).
      IF sy-subrc = 0.
        APPEND VALUE #(
          source-InspectionLot              = <key>-InspectionLot
          source-InspPlanOperationInternalID = <key>-InspPlanOperationInternalID
          source-InspectionCharacteristic    = <key>-InspectionCharacteristic
          target-InspectionLot              = ls-InspectionLot
        ) TO association_links.
        APPEND ls TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

*  METHOD get_instance_features.
*  ENDMETHOD.

 METHOD vormerken.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DATA ls_vm TYPE zjmqmit_dl_token.
      ls_vm-created_by = sy-uname.
      ls_vm-prueflos   = <key>-InspectionLot.
      GET TIME STAMP FIELD ls_vm-created_at.
      INSERT zjmqmit_dl_token FROM ls_vm.
    ENDLOOP.

    reported-insplot = VALUE #( BASE reported-insplot
      ( %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |{ lines( keys ) } Prüflos(e) vorgemerkt – jetzt "Vormerkliste laden" klicken|
               )
      )
    ).
  ENDMETHOD.

  METHOD vormerkliste_leeren.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DELETE FROM zjmqmit_dl_token
        WHERE prueflos = @<key>-InspectionLot.
    ENDLOOP.
    reported-insplot = VALUE #( BASE reported-insplot
      ( %tky = keys[ 1 ]-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = 'Vormerkliste wurde geleert'
               )
      )
    ).
  ENDMETHOD.

  METHOD vormerken_loeschen.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<vl_key>).
      DELETE FROM zjmqmit_dl_token
        WHERE prueflos   = @<vl_key>-InspectionLot
          AND created_by = @sy-uname.
    ENDLOOP.
    IF keys IS NOT INITIAL.
      reported-insplot = VALUE #( BASE reported-insplot
        ( %tky = keys[ 1 ]-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-success
                   text     = 'Prüflos aus Vormerkliste entfernt'
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
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key2>).
      SELECT SINGLE prueflos, created_by, created_at
        FROM zjmqmit_dl_token
        WHERE prueflos   = @<key2>-InspectionLot
          AND created_by = @<key2>-CreatedBy
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
    LOOP AT keys_for_read ASSIGNING FIELD-SYMBOL(<key3>).
      SELECT SINGLE * FROM zjmqmi_i_insplot
        WHERE InspectionLot = @<key3>-InspectionLot
        INTO @DATA(ls_il).
      IF sy-subrc = 0.
        APPEND VALUE #(
          source-InspectionLot = <key3>-InspectionLot
          source-CreatedBy     = <key3>-CreatedBy
          target-InspectionLot = ls_il-InspectionLot
        ) TO association_links.
        APPEND ls_il TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD _parse_xlsx.
    " ZIP entpacken → sheet1.xml lesen → Zeilen/Zellen parsen
    DATA lo_zip     TYPE REF TO cl_abap_zip.
    DATA lv_xml_raw TYPE xstring.
    DATA lv_xml     TYPE string.
    DATA ls_row     TYPE ty_upload_row.
    DATA lv_row_nr  TYPE i.

    " ZIP laden
    CREATE OBJECT lo_zip.
    lo_zip->load( EXPORTING zip    = iv_xstring
                  EXCEPTIONS others = 1 ).
    CHECK sy-subrc = 0.

    " sheet1.xml entpacken
    lo_zip->get( EXPORTING  name    = 'xl/worksheets/sheet1.xml'
                 IMPORTING  content = lv_xml_raw
                 EXCEPTIONS others  = 1 ).
    CHECK sy-subrc = 0.

    lv_xml = cl_abap_codepage=>convert_from( source   = lv_xml_raw
                                             codepage = 'UTF-8' ).

    " Zeilenweise parsen: <row r="N">...</row>
    DATA lv_rest   TYPE string.
    DATA lv_rowxml TYPE string.
    DATA lv_rattr  TYPE string.
    DATA lv_rownum TYPE string.
    lv_rest = lv_xml.

    FIND FIRST OCCURRENCE OF REGEX `<row r="(\d+)"` IN lv_rest
      SUBMATCHES lv_rownum.

    WHILE sy-subrc = 0.
      " Row-Inhalt bis </row> extrahieren
      FIND FIRST OCCURRENCE OF `</row>` IN lv_rest MATCH OFFSET DATA(lv_end).
      lv_rowxml = substring( val = lv_rest off = 0 len = lv_end ).
      lv_rest   = substring( val = lv_rest off = lv_end + 6 ).

      " Zeile 1 = Header überspringen
      IF lv_rownum = '1'.
        FIND FIRST OCCURRENCE OF REGEX `<row r="(\d+)"` IN lv_rest
          SUBMATCHES lv_rownum.
        CONTINUE.
      ENDIF.

      lv_row_nr = lv_rownum.
      CLEAR ls_row.
      ls_row-excel_row = lv_row_nr.

      " Alle Zellen <c r="XN" t="inlineStr"><is><t>text</t></is></c> parsen
      DATA lv_cell_rest TYPE string.
      lv_cell_rest = lv_rowxml.
      DATA lv_col_let   TYPE string.
      DATA lv_cell_val  TYPE string.
      DATA lv_col_idx   TYPE i.
      DATA lv_t_start   TYPE i.
      DATA lv_t_end     TYPE i.
      DATA lv_t_off     TYPE i.
      DATA lv_t_len     TYPE i.
      DATA lv_c_end     TYPE i.

      FIND FIRST OCCURRENCE OF REGEX `<c r="([A-Z]+)\d+"` IN lv_cell_rest
        SUBMATCHES lv_col_let.

      WHILE sy-subrc = 0.
        " Zellwert lesen
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

        " Spaltenindex ermitteln
        lv_col_idx = _col_letter_to_idx( lv_col_let ).

        " Relevante Spalten befüllen
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

        " Nächste Zelle: ab nach </c> weitersuchen
        FIND FIRST OCCURRENCE OF `</c>` IN lv_cell_rest MATCH OFFSET lv_c_end.
        lv_cell_rest = substring( val = lv_cell_rest off = lv_c_end + 4 ).
        FIND FIRST OCCURRENCE OF REGEX `<c r="([A-Z]+)\d+"` IN lv_cell_rest
          SUBMATCHES lv_col_let.
      ENDWHILE.

      " Zeile nur übernehmen wenn Prüflos und Merkmal gefüllt
      IF ls_row-prueflosnummer IS NOT INITIAL AND ls_row-merkmalsnummer IS NOT INITIAL.
        APPEND ls_row TO rt_rows.
      ENDIF.

      " Nächste Row suchen
      FIND FIRST OCCURRENCE OF REGEX `<row r="(\d+)"` IN lv_rest
        SUBMATCHES lv_rownum.
    ENDWHILE.
  ENDMETHOD.

  METHOD _get_codes_for_char.
    " Vorglfnr (intern) via CDS aus externer VORNR ermitteln
    DATA lv_vorglfnr TYPE qamv-vorglfnr.
    SELECT SINGLE InspPlanOperationInternalID
      FROM ZJMQMI_I_INSPLOT_CHAR
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @lv_vorglfnr.
    CHECK sy-subrc = 0.
    " QAMV: Katalog und Auswahlmenge lesen
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
    " Codes aus QPAC (mit Codegruppe), gleiche Reihenfolge wie Download
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
    DATA ls_prot   TYPE zjmqmit_prot.
    DATA lo_uuid   TYPE REF TO if_system_uuid.
    DATA lv_guid   TYPE sysuuid_c32.
    lo_uuid = CAST if_system_uuid( cl_uuid_factory=>create_system_uuid( ) ).
    lv_guid = lo_uuid->create_uuid_c32( ).
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
    rv_result = 'A'.
    CHECK iv_messwert IS NOT INITIAL.
    SELECT SINGLE InspSpecUpperLimit, InspSpecLowerLimit
      FROM zjmqmi_i_insplot_char
      WHERE InspectionLot            = @iv_prueflos
        AND InspectionOperation      = @iv_vornr
        AND InspectionCharacteristic = @iv_merknr
      INTO @DATA(ls_lim).
    CHECK sy-subrc = 0.
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
    " Vorgangsnummern (eindeutig) ermitteln
    DATA lt_vorgnr TYPE TABLE OF string WITH EMPTY KEY.
    LOOP AT it_rows INTO DATA(ls_r).
      APPEND condense( ls_r-vorgangsnummer ) TO lt_vorgnr.
    ENDLOOP.
    SORT lt_vorgnr.
    DELETE ADJACENT DUPLICATES FROM lt_vorgnr.

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
            DATA(lv_res_no) = _get_next_res_no(
              iv_prueflos = iv_prueflos
              iv_inspoper = CONV vornr( lv_vornr )
              iv_inspchar = CONV qamv-merknr( ls_row-merkmalsnummer )
            ).
            DATA lv_ep_codegrp TYPE qpac-codegruppe.
            DATA lv_ep_code    TYPE qpac-code.
            CLEAR: lv_ep_codegrp, lv_ep_code.
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

      " BAPI aufrufen
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

      " Protokoll schreiben (eine Zeile pro Merkmal in dieser Gruppe)
      LOOP AT it_rows INTO DATA(ls_rp) WHERE vorgangsnummer = lv_vornr.
        DATA lv_prot_msg  TYPE string.
        DATA lv_prot_stat TYPE c LENGTH 1.
        lv_prot_stat = 'S'.
        CLEAR lv_prot_msg.
        LOOP AT lt_return INTO DATA(ls_ret)
          WHERE type = 'E' OR type = 'A'.
          lv_prot_stat = 'E'.
          lv_ul_status = 'E'.
          lv_prot_msg  = ls_ret-message.
          EXIT.
        ENDLOOP.
        IF lv_prot_stat = 'S'.
          IF ls_rp-quanqual = 'QN'.
            DATA(lv_pm_eval) = _get_evaluation(
              iv_prueflos = iv_prueflos
              iv_vornr    = condense( ls_rp-vorgangsnummer )
              iv_merknr   = condense( ls_rp-merkmalsnummer )
              iv_messwert = ls_rp-messwert
            ).
            lv_prot_msg = |Bewertung erfolgreich: { lv_pm_eval } - { ls_rp-messwert }|.
          ELSE.
            IF ls_rp-code_col_idx > 0.
              DATA(lt_pc) = _get_codes_for_char(
                iv_prueflos = iv_prueflos
                iv_vornr    = condense( ls_rp-vorgangsnummer )
                iv_merknr   = condense( ls_rp-merkmalsnummer )
              ).
              READ TABLE lt_pc INDEX ( ls_rp-code_col_idx - 26 ) INTO DATA(ls_pc).
              IF sy-subrc = 0.
                lv_prot_msg = |Bewertung erfolgreich: { ls_pc-bewertung } - { condense( ls_pc-kurztext ) }|.
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

    " Commit nach allen BAPI-Aufrufen dieser Prüflosnummer
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = 'X'.

    " Upload-Status aktualisieren
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

    " XLSX parsen
    DATA(lt_rows) = _parse_xlsx( lv_content ).
    CHECK lt_rows IS NOT INITIAL.

    " Eindeutige Prüflosnummern ermitteln
    DATA lt_lots TYPE TABLE OF qals-prueflos WITH EMPTY KEY.
    LOOP AT lt_rows INTO DATA(ls_r).
      DATA(lv_lot) = CONV qals-prueflos( condense( ls_r-prueflosnummer ) ).
      APPEND lv_lot TO lt_lots.
    ENDLOOP.
    SORT lt_lots.
    DELETE ADJACENT DUPLICATES FROM lt_lots.

    " Pro Prüflos verbuchen
    LOOP AT lt_lots INTO DATA(lv_lot2).
      DATA(lt_lot_rows) = VALUE ty_upload_rows(
        FOR r IN lt_rows WHERE ( prueflosnummer = lv_lot2 ) ( r )
      ).
      _post_results(
        iv_prueflos = lv_lot2
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
                   text     = |{ lv_count } Prüflos(e) zurückgesetzt|
                 )
        )
      ).
    ENDIF.
  ENDMETHOD.

  METHOD _col_letter_to_idx.
    " Wandelt Spaltenbrief (z.B. 'A'→1, 'Z'→26, 'AA'→27, 'AB'→28) in Integer um
    DATA lc      TYPE c LENGTH 26.
    DATA lv_col  TYPE c LENGTH 10.
    DATA lv_ch   TYPE c LENGTH 1.
    DATA lv_pos  TYPE i.
    DATA lv_len  TYPE i.
    DATA lv_off  TYPE i.
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

ENDCLASS.
