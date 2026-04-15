CLASS zjmqmi_cl_icf_upload DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.
ENDCLASS.

CLASS zjmqmi_cl_icf_upload IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA(lv_method)  = server->request->get_method( ).
    DATA(lv_lot_str) = server->request->get_form_field( 'lot' ).

    " ── GET: HTML-Formular ausliefern ──────────────────────────────────────
    IF lv_method = 'GET'.
      DATA lv_title TYPE string.
      DATA lv_lot_js TYPE string.
      IF lv_lot_str IS NOT INITIAL.
        lv_title  = |Prüflos { condense( lv_lot_str ) } hochladen|.
        lv_lot_js = |'{ condense( lv_lot_str ) }'|.
      ELSE.
        lv_title  = 'Vormerkliste hochladen'.
        lv_lot_js = 'null'.
      ENDIF.
      DATA(lv_html) =
        `<!DOCTYPE html><html lang="de"><head><meta charset="UTF-8">` &&
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
        `<label for="fi">Excel-Datei (.xlsx)</label>` &&
        `<input type="file" id="fi" accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">` &&
        `<div class="cb">` &&
        `<input type="checkbox" id="ow">` &&
        `<label for="ow" style="color:#32363a;margin:0;cursor:pointer">Ergebnisse &#252;berschreiben</label>` &&
        `</div>` &&
        `<div class="btns">` &&
        `<button class="p" onclick="go()">Hochladen</button>` &&
        `<button class="s" onclick="history.back()">Zur&#252;ck</button>` &&
        `</div><div id="st"></div>` &&
        `<script>` &&
        `var LOT=` && lv_lot_js && `;` &&
        `function go(){` &&
        `var f=document.getElementById('fi').files[0];` &&
        `if(!f){show('Bitte eine Datei ausw\u00e4hlen.',false);return;}` &&
        `var ow=document.getElementById('ow').checked;` &&
        `show('Wird verarbeitet\u2026',null);` &&
        `var r=new FileReader();` &&
        `r.onload=function(e){` &&
        `var url=window.location.pathname+'?filename='+encodeURIComponent(f.name);` &&
        `if(LOT)url+='&lot='+encodeURIComponent(LOT);` &&
        `if(ow)url+='&overwrite=1';` &&
        `var x=new XMLHttpRequest();` &&
        `x.open('POST',url,true);` &&
        `x.setRequestHeader('Content-Type','application/octet-stream');` &&
        `x.onload=function(){show(x.responseText,x.status===200);};` &&
        `x.onerror=function(){show('Netzwerkfehler beim Hochladen.',false);};` &&
        `x.send(e.target.result);};` &&
        `r.readAsArrayBuffer(f);}` &&
        `function show(m,ok){var e=document.getElementById('st');` &&
        `e.style.display='block';` &&
        `e.className=ok===true?'ok':ok===false?'er':'wa';` &&
        `e.textContent=m;}` &&
        `</script></body></html>`.
      server->response->set_content_type( 'text/html; charset=utf-8' ).
      server->response->set_cdata( lv_html ).
      server->response->set_status( code = 200 reason = 'OK' ).
      RETURN.
    ENDIF.

    " ── POST: Datei verarbeiten ─────────────────────────────────────────────
    IF lv_method = 'POST'.
      DATA lv_xstring  TYPE xstring.
      DATA lv_filename TYPE string.
      lv_xstring  = server->request->get_data( ).
      lv_filename = server->request->get_form_field( 'filename' ).
      IF lv_filename IS INITIAL. lv_filename = 'upload.xlsx'. ENDIF.

      DATA(lv_overwrite_str) = server->request->get_form_field( 'overwrite' ).
      DATA lv_overwrite TYPE abap_bool.
      IF lv_overwrite_str = '1'. lv_overwrite = abap_true. ENDIF.

      IF lv_xstring IS INITIAL.
        server->response->set_status( code = 400 reason = 'Bad Request' ).
        server->response->set_cdata( 'Kein Dateiinhalt empfangen.' ).
        RETURN.
      ENDIF.

      " Filter-Lots bestimmen: Einzel-Upload (lot=) oder Batch (Vormerkliste)
      DATA lt_filter TYPE zjmqmi_cl_upload_helper=>ty_filter_lots.
      DATA lv_is_batch TYPE abap_bool.
      IF lv_lot_str IS NOT INITIAL.
        APPEND CONV qals-prueflos( condense( lv_lot_str ) ) TO lt_filter.
      ELSE.
        lv_is_batch = abap_true.
        SELECT prueflos FROM zjmqmit_dl_token
          WHERE created_by = @sy-uname
          ORDER BY prueflos
          INTO TABLE @lt_filter.
        IF lt_filter IS INITIAL.
          server->response->set_status( code = 404 reason = 'Keine Prueflose vorgemerkt' ).
          server->response->set_cdata( 'Keine Prüflose in der Vormerkliste gefunden.' ).
          RETURN.
        ENDIF.
      ENDIF.

      DATA lo_helper TYPE REF TO zjmqmi_cl_upload_helper.
      CREATE OBJECT lo_helper.
      DATA(lv_msg) = lo_helper->process_upload(
        iv_filename    = lv_filename
        iv_xstring     = lv_xstring
        it_filter_lots = lt_filter
        iv_overwrite   = lv_overwrite
      ).

      " Batch-Upload: Vormerkliste bereinigen
      IF lv_is_batch = abap_true.
        DELETE FROM zjmqmit_dl_token WHERE created_by = @sy-uname.
        COMMIT WORK.
      ENDIF.

      server->response->set_content_type( 'text/plain; charset=utf-8' ).
      server->response->set_cdata( lv_msg ).
      server->response->set_status( code = 200 reason = 'OK' ).
      RETURN.
    ENDIF.

    server->response->set_status( code = 405 reason = 'Method Not Allowed' ).
  ENDMETHOD.

ENDCLASS.

