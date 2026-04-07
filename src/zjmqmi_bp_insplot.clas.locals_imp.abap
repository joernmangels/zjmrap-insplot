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
          InspectionLot       = <p>-prueflos
          ProtGuid            = <p>-prot_guid
          ProtTimestamp       = <p>-prot_timestamp
          FileName            = <p>-prot_filename
          RowNumber           = <p>-prot_rownr
          InspectionOperation = <p>-prot_inspoper
          Status              = <p>-prot_status
          Message             = <p>-prot_msg
          CreatedBy           = <p>-created_by
          CreatedAt           = <p>-created_at
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
          InspectionLot       = ls-prueflos
          ProtGuid            = ls-prot_guid
          ProtTimestamp       = ls-prot_timestamp
          FileName            = ls-prot_filename
          RowNumber           = ls-prot_rownr
          InspectionOperation = ls-prot_inspoper
          Status              = ls-prot_status
          Message             = ls-prot_msg
          CreatedBy           = ls-created_by
          CreatedAt           = ls-created_at ) TO result.
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

ENDCLASS.
