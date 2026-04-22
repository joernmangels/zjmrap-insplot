CLASS zjmqmi_cl_icf_proxy DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.
  PRIVATE SECTION.
    CONSTANTS gc_destination TYPE rfcdest VALUE 'ZJMQMI_BACKEND'.
    METHODS _copy_header
      IMPORTING io_from TYPE REF TO if_http_entity
                io_to   TYPE REF TO if_http_entity
                iv_name TYPE string.
ENDCLASS.



CLASS ZJMQMI_CL_ICF_PROXY IMPLEMENTATION.


  METHOD if_http_extension~handle_request.
    DATA lo_client TYPE REF TO if_http_client.

    cl_http_client=>create_by_destination(
      EXPORTING  destination              = gc_destination
      IMPORTING  client                   = lo_client
      EXCEPTIONS argument_not_found       = 1
                 destination_not_found    = 2
                 destination_no_authority = 3
                 plugin_not_active        = 4
                 OTHERS                   = 5 ).
    IF sy-subrc <> 0.
      server->response->set_status( code = 503 reason = 'Backend-Destination nicht verfuegbar' ).
      RETURN.
    ENDIF.

    " Vollständige URI (Pfad + Query) aus dem eingehenden Request übernehmen
    DATA(lv_uri) = server->request->get_header_field( '~request_uri' ).
    DATA(lv_method) = server->request->get_header_field( '~request_method' ).

    lo_client->request->set_header_field( name = '~request_method' value = lv_method ).
    lo_client->request->set_header_field( name = '~request_uri'    value = lv_uri    ).

    " Relevante Request-Header weiterleiten
    _copy_header( io_from = server->request io_to = lo_client->request iv_name = 'content-type'   ).
    _copy_header( io_from = server->request io_to = lo_client->request iv_name = 'content-length' ).
    _copy_header( io_from = server->request io_to = lo_client->request iv_name = 'accept'         ).

    " Body weiterleiten (für POST/PUT mit XLSX-Upload)
    DATA(lv_body) = server->request->get_data( ).
    IF lv_body IS NOT INITIAL.
      lo_client->request->set_data( lv_body ).
    ENDIF.

    lo_client->send(
      EXCEPTIONS http_communication_failure = 1
                 http_invalid_state         = 2
                 OTHERS                     = 3 ).
    IF sy-subrc <> 0.
      server->response->set_status( code = 502 reason = 'Fehler beim Senden an Backend' ).
      lo_client->close( ).
      RETURN.
    ENDIF.

    lo_client->receive(
      EXCEPTIONS http_communication_failure = 1
                 http_invalid_state         = 2
                 http_processing_failed     = 3
                 OTHERS                     = 4 ).
    IF sy-subrc <> 0.
      server->response->set_status( code = 502 reason = 'Fehler beim Empfangen vom Backend' ).
      lo_client->close( ).
      RETURN.
    ENDIF.

    " Status vom Backend übernehmen
    DATA lv_code   TYPE i.
    DATA lv_reason TYPE string.
    lo_client->response->get_status( IMPORTING code = lv_code reason = lv_reason ).
    server->response->set_status( code = lv_code reason = lv_reason ).

    " Relevante Response-Header weiterleiten
    _copy_header( io_from = lo_client->response io_to = server->response iv_name = 'content-type'        ).
    _copy_header( io_from = lo_client->response io_to = server->response iv_name = 'content-disposition' ).

    " Body (bei Download: binäre XLSX-Daten)
    server->response->set_data( lo_client->response->get_data( ) ).

    lo_client->close( ).
  ENDMETHOD.


  METHOD _copy_header.
    DATA(lv_val) = io_from->get_header_field( iv_name ).
    CHECK lv_val IS NOT INITIAL.
    io_to->set_header_field( name = iv_name value = lv_val ).
  ENDMETHOD.
ENDCLASS.
