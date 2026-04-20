REPORT zjmqmi_set_ul_texts.

" Einmalig ausführen in SA38 — setzt TEXT-001..014 für ZJMQMI_CL_ICF_UPLOAD (Sprache EN)

DATA lt_pool TYPE TABLE OF textpool WITH EMPTY KEY.

DEFINE add_sym.
  INSERT VALUE textpool( id     = 'S'
                         key    = &1
                         entry  = &2
                         length = strlen( &2 ) ) INTO TABLE lt_pool.
END-OF-DEFINITION.

add_sym '001' 'Method Not Allowed'.
add_sym '002' 'Bad Request'.
add_sym '003' 'No inspection lots in watchlist'.
add_sym '004' 'No file content received.'.
add_sym '005' 'No inspection lots found in watchlist.'.
add_sym '006' 'Upload Inspection Lot'.
add_sym '007' 'Upload Watchlist'.
add_sym '008' 'Excel File (.xlsx)'.
add_sym '009' 'Overwrite Results'.
add_sym '010' 'Upload'.
add_sym '011' 'Back'.
add_sym '012' 'Please select a file.'.
add_sym '013' 'Processing...'.
add_sym '014' 'Network error while uploading.'.

INSERT TEXTPOOL 'ZJMQMI_CL_ICF_UPLOAD'
  FROM lt_pool
  LANGUAGE 'E'.

IF sy-subrc = 0.
  MESSAGE 'Text symbols for ZJMQMI_CL_ICF_UPLOAD set (EN).' TYPE 'S'.
ELSE.
  MESSAGE |Error: sy-subrc={ sy-subrc }| TYPE 'E'.
ENDIF.
