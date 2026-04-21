CLASS zjmqmi_cl_icf_upload DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

  PRIVATE SECTION.
    METHODS handle_get
      IMPORTING server     TYPE REF TO if_http_server
                iv_lot_str TYPE string.
    METHODS handle_post
      IMPORTING server     TYPE REF TO if_http_server
                iv_lot_str TYPE string.
    METHODS build_html
      IMPORTING iv_lot_str     TYPE string
      RETURNING VALUE(rv_html) TYPE string.
ENDCLASS.

CLASS zjmqmi_cl_icf_upload IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA(lv_method)  = server->request->get_method( ).
    DATA(lv_lot_str) = server->request->get_form_field( `lot` ).
    CASE lv_method.
      WHEN `GET`.
        handle_get(  server = server iv_lot_str = lv_lot_str ).
      WHEN `POST`.
        handle_post( server = server iv_lot_str = lv_lot_str ).
      WHEN OTHERS.
        server->response->set_status( code = 405 reason = |{ TEXT-001 }| ).
    ENDCASE.
  ENDMETHOD.


  METHOD handle_get.
    server->response->set_content_type( `text/html; charset=utf-8` ).
    server->response->set_cdata( build_html( iv_lot_str ) ).
    server->response->set_status( code = 200 reason = `OK` ).
  ENDMETHOD.


  METHOD handle_post.
    DATA(lv_xstring)  = server->request->get_data( ).
    DATA(lv_filename) = server->request->get_form_field( `filename` ).
    IF lv_filename IS INITIAL.
      lv_filename = `upload.xlsx`.
    ENDIF.

    DATA(lv_overwrite) = COND abap_bool(
      WHEN server->request->get_form_field( `overwrite` ) = `1`
      THEN abap_true
      ELSE abap_false ).

    IF lv_xstring IS INITIAL.
      server->response->set_status( code = 400 reason = |{ TEXT-002 }| ).
      server->response->set_cdata( |{ TEXT-004 }| ).
      RETURN.
    ENDIF.

    DATA lt_filter TYPE zjmqmi_cl_upload_helper=>ty_filter_lots.
    IF iv_lot_str IS NOT INITIAL.
      INSERT CONV qals-prueflos( condense( iv_lot_str ) ) INTO TABLE lt_filter.
    ELSE.
      SELECT prueflos FROM zjmqmit_dl_token
        ORDER BY prueflos
        INTO TABLE @lt_filter.
      IF lt_filter IS INITIAL.
        server->response->set_status( code = 404 reason = |{ TEXT-003 }| ).
        server->response->set_cdata( |{ TEXT-005 }| ).
        RETURN.
      ENDIF.
    ENDIF.

    DATA(lo_helper) = NEW zjmqmi_cl_upload_helper( ).
    DATA(lv_msg) = lo_helper->process_upload(
      iv_filename    = lv_filename
      iv_xstring     = lv_xstring
      it_filter_lots = lt_filter
      iv_overwrite   = lv_overwrite
    ).

    COMMIT WORK.

    LOOP AT lt_filter ASSIGNING FIELD-SYMBOL(<lot>).
      SELECT SINGLE last_ul_status FROM zjmqmit_status
        WHERE prueflos = @<lot>
        INTO @DATA(lv_ul_status).
      IF sy-subrc = 0 AND lv_ul_status = 'S'.
        DELETE FROM zjmqmit_dl_token WHERE prueflos = @<lot>.
      ENDIF.
    ENDLOOP.
    COMMIT WORK.

    server->response->set_content_type( `text/plain; charset=utf-8` ).
    server->response->set_cdata( lv_msg ).
    server->response->set_status( code = 200 reason = `OK` ).
  ENDMETHOD.


  METHOD build_html.
    DATA(lv_title) = COND string(
      WHEN iv_lot_str IS NOT INITIAL
      THEN |{ TEXT-006 } { condense( iv_lot_str ) }|
      ELSE |{ TEXT-007 }| ).
    DATA(lv_lot_js) = COND string(
      WHEN iv_lot_str IS NOT INITIAL
      THEN |'{ condense( iv_lot_str ) }'|
      ELSE `null` ).

    rv_html =
      `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">` &&
      `<title>` && lv_title && `</title><style>` &&
      `body{font-family:"72",Arial,sans-serif;max-width:560px;margin:60px auto;padding:0 20px;color:#32363a}` &&
      `h1{font-size:1.4rem;font-weight:300;margin-bottom:1.5rem}` &&
      `label{display:block;font-size:.875rem;color:#6a6d70;margin-bottom:6px}` &&
      `input[type=file]{width:100%;font-size:.9rem;padding:6px 0}` &&
      `.cb{margin-top:1rem;display:flex;align-items:center;gap:8px;font-size:.9rem;color:#32363a;cursor:pointer}` &&
      `.cb input{width:16px;height:16px;cursor:pointer;accent-color:#0070f2}` &&
      `.btns{margin-top:1.5rem;display:flex;gap:12px}` &&
      `button.p{background:#0070f2;color:#fff;border:none;padding:10px 24px;border-radius:4px;font-size:.9rem;cursor:pointer}` &&
      `button.p:hover{background:#0057d2}` &&
      `button.s{background:none;border:1px solid #bbb;padding:10px 24px;border-radius:4px;font-size:.9rem;cursor:pointer}` &&
      `#st{margin-top:1.2rem;font-size:.9rem;padding:10px 14px;border-radius:4px;display:none;white-space:pre-wrap}` &&
      `#st.ok{background:#f1fdf6;color:#107e3e;border:1px solid #abe5c2}` &&
      `#st.er{background:#fff6f6;color:#bb0000;border:1px solid #f5c2c2}` &&
      `#st.wa{background:#fffbf0;color:#6a4f00;border:1px solid #f5e2a0}` &&
      `</style></head><body>` &&
      `<h1>` && lv_title && `</h1>` &&
      `<label for="fi">` && |{ TEXT-008 }| && `</label>` &&
      `<input type="file" id="fi" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">` &&
      `<div class="cb">` &&
      `<input type="checkbox" id="ow">` &&
      `<label for="ow" style="color:#32363a;margin:0;cursor:pointer">` && |{ TEXT-009 }| && `</label>` &&
      `</div>` &&
      `<div class="btns">` &&
      `<button class="p" onclick="go()">` && |{ TEXT-010 }| && `</button>` &&
      `<button class="s" onclick="history.back()">` && |{ TEXT-011 }| && `</button>` &&
      `</div><div id="st"></div>` &&
      `<script>` &&
      `var LOT=` && lv_lot_js && `;` &&
      `function go(){` &&
      `var f=document.getElementById('fi').files[0];` &&
      `if(!f){show('` && condense( TEXT-012 ) && `',false);return;}` &&
      `var ow=document.getElementById('ow').checked;` &&
      `show('` && condense( TEXT-013 ) && `',null);` &&
      `var r=new FileReader();` &&
      `r.onload=function(e){` &&
      `var url=window.location.pathname+'?filename='+encodeURIComponent(f.name);` &&
      `if(LOT)url+='&lot='+encodeURIComponent(LOT);` &&
      `if(ow)url+='&overwrite=1';` &&
      `var x=new XMLHttpRequest();` &&
      `x.open('POST',url,true);` &&
      `x.setRequestHeader('Content-Type','application/octet-stream');` &&
      `x.onload=function(){show(x.responseText,x.status===200);};` &&
      `x.onerror=function(){show('` && condense( TEXT-014 ) && `',false);};` &&
      `x.send(e.target.result);};` &&
      `r.readAsArrayBuffer(f);}` &&
      `function show(m,ok){var e=document.getElementById('st');` &&
      `e.style.display='block';` &&
      `e.className=ok===true?'ok':ok===false?'er':'wa';` &&
      `e.textContent=m;}` &&
      `</script></body></html>`.
  ENDMETHOD.

ENDCLASS.

