REPORT zjmqmi_set_dl_texts.

" Einmalig ausführen in SA38 — setzt TEXT-001..027 für ZJMQMI_CL_ICF_DOWNLOAD (Sprache EN)

DATA lt_pool TYPE TABLE OF textpool WITH EMPTY KEY.

DEFINE add_sym.
  INSERT VALUE textpool( id     = 'S'
                         key    = &1
                         entry  = &2
                         length = strlen( &2 ) ) INTO TABLE lt_pool.
END-OF-DEFINITION.

add_sym '001' 'Inspection Lot'.
add_sym '002' 'Task List Group'.
add_sym '003' 'TL Variant'.
add_sym '004' 'Task List Description'.
add_sym '005' 'Supplier No.'.
add_sym '006' 'Purchase Order'.
add_sym '007' 'PO Item'.
add_sym '008' 'Material'.
add_sym '009' 'Mat. Status'.
add_sym '010' 'Operation'.
add_sym '011' 'Operation Description'.
add_sym '012' 'Sampling Proc.'.
add_sym '013' 'Sampling Proc. Descr.'.
add_sym '014' 'Master Characteristic'.
add_sym '015' 'QN/QL'.
add_sym '016' 'Characteristic'.
add_sym '017' 'Short Text'.
add_sym '018' 'Inspection Method'.
add_sym '019' 'Target Value QL'.
add_sym '020' 'Catalog QL'.
add_sym '021' 'Long Text'.
add_sym '022' 'Target Value QN'.
add_sym '023' 'Upper Limit'.
add_sym '024' 'Lower Limit'.
add_sym '025' 'Lot Size'.
add_sym '026' 'QC Department'.
add_sym '027' 'Valuation / Code 1'.
add_sym '028' 'No inspection lots in watchlist'.

INSERT TEXTPOOL 'ZJMQMI_CL_ICF_DOWNLOAD'
  FROM lt_pool
  LANGUAGE 'E'.

IF sy-subrc = 0.
  MESSAGE 'Text symbols for ZJMQMI_CL_ICF_DOWNLOAD set (EN).' TYPE 'S'.
ELSE.
  MESSAGE |Error: sy-subrc={ sy-subrc }| TYPE 'E'.
ENDIF.
