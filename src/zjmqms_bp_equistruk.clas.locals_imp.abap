*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lhc_equistruk DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    " Tabelle ZJMQM_QM009_Q hat die Ebenenfelder MAT_EBENE0 bis MAT_EBENE19
    CONSTANTS c_levels TYPE i VALUE 20.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR equistruk RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE equistruk.

    METHODS normalizematerial FOR DETERMINE ON MODIFY
      IMPORTING keys FOR equistruk~normalizematerial.

    METHODS validaterow FOR VALIDATE ON SAVE
      IMPORTING keys FOR equistruk~validaterow.

    CONSTANTS c_max_level TYPE i VALUE 19.

    TYPES tt_keys TYPE TABLE FOR READ IMPORT zjmqms_i_equistruk.
    TYPES ty_key  TYPE STRUCTURE FOR READ IMPORT zjmqms_i_equistruk.

    TYPES: BEGIN OF ty_problem,
             key  TYPE ty_key,
             text TYPE string,
           END OF ty_problem.
    TYPES tt_problems TYPE STANDARD TABLE OF ty_problem WITH EMPTY KEY.

    METHODS einruecken FOR MODIFY
      IMPORTING keys FOR ACTION equistruk~einruecken.

    METHODS ausruecken FOR MODIFY
      IMPORTING keys FOR ACTION equistruk~ausruecken.

    METHODS setebene FOR MODIFY
      IMPORTING keys FOR ACTION equistruk~setebene.

    "! Verschiebt die Materialnummer der Zeilen auf eine andere Ebene.
    "! Leeren des alten und Setzen des neuen Feldes passieren in einem Zug,
    "! deshalb kann kein ungueltiger Zwischenstand entstehen.
    "!
    "! @parameter iv_delta  | relative Verschiebung, wenn iv_target negativ ist
    "! @parameter iv_target | absolute Zielebene ab 0, sonst -1
    METHODS move_level
      IMPORTING it_keys     TYPE tt_keys
                iv_delta    TYPE i DEFAULT 0
                iv_target   TYPE i DEFAULT -1
      EXPORTING et_problems TYPE tt_problems.

    "! Ebene und Materialnummer einer gelesenen Zeile bestimmen.
    "! ev_level ist -1, wenn kein Ebenenfeld gefuellt ist.
    METHODS current_level
      IMPORTING is_row      TYPE any
      EXPORTING ev_level    TYPE i
                ev_material TYPE matnr.

    "! Prueft die Ebenenfolge der betroffenen Pruefplaene.
    "!
    "! Eine Zeile darf gegenueber ihrer Vorgaengerzeile hoechstens EINE Ebene
    "! tiefer liegen - sonst fehlt ihr das uebergeordnete Material. Nach oben
    "! sind beliebige Ruecksprunge erlaubt, Geschwister auf gleicher Ebene
    "! ebenfalls. Die erste Zeile eines Plans muss auf Ebene 0 liegen.
    "!
    "! Geprueft wird immer der ganze Plan, nicht nur die geaenderten Zeilen:
    "! eine Verschiebung kann auch die nachfolgende Zeile ungueltig machen.
    METHODS check_hierarchy
      IMPORTING it_keys     TYPE tt_keys
      EXPORTING et_problems TYPE tt_problems.

    TYPES tt_rows   TYPE TABLE FOR READ RESULT zjmqms_i_equistruk.
    TYPES ty_update TYPE STRUCTURE FOR UPDATE zjmqms_i_equistruk.

    METHODS nachoben FOR MODIFY
      IMPORTING keys FOR ACTION equistruk~nachoben.

    METHODS nachunten FOR MODIFY
      IMPORTING keys FOR ACTION equistruk~nachunten.

    METHODS setposition FOR MODIFY
      IMPORTING keys FOR ACTION equistruk~setposition.

    "! Liest alle Zeilen eines Pruefplans, nach laufender Nummer sortiert.
    "!
    "! Beruecksichtigt den Transaktionspuffer: noch nicht gesicherte
    "! Aenderungen sind enthalten, in dieser Transaktion geloeschte Zeilen
    "! kommen nicht zurueck. Ueber it_extra_keys lassen sich Zeilen ergaenzen,
    "! die neu angelegt wurden und deshalb noch nicht in der Datenbank stehen.
    METHODS read_plan_rows
      IMPORTING is_key        TYPE ty_key
                it_extra_keys TYPE tt_keys OPTIONAL
      EXPORTING et_rows       TYPE tt_rows.

    "! Verschiebt eine Zeile innerhalb ihres Plans nach oben oder unten.
    "!
    "! LFDNR ist Schluesselfeld und bleibt deshalb unangetastet - verschoben
    "! wird der INHALT: die Materialnummern rotieren ueber den betroffenen
    "! Bereich, die laufenden Nummern bleiben stehen. Optisch dasselbe,
    "! kommt aber ohne Schluesseleingriff aus.
    "!
    "! @parameter iv_delta  | relative Verschiebung, wenn iv_target negativ ist
    "! @parameter iv_target | absolute Ziel-LFDNR, sonst -1
    METHODS move_position
      IMPORTING it_keys     TYPE tt_keys
                iv_delta    TYPE i DEFAULT 0
                iv_target   TYPE i DEFAULT -1
      EXPORTING et_problems TYPE tt_problems.

ENDCLASS.


CLASS lhc_equistruk IMPLEMENTATION.

  METHOD nachoben.

    move_position( EXPORTING it_keys     = CORRESPONDING #( keys )
                             iv_delta    = -1
                   IMPORTING et_problems = DATA(problems) ).

    LOOP AT problems INTO DATA(problem).
      APPEND VALUE #( %tky = problem-key-%tky ) TO failed-equistruk.
      APPEND VALUE #( %tky = problem-key-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = problem-text ) )
             TO reported-equistruk.
    ENDLOOP.

  ENDMETHOD.


  METHOD nachunten.

    move_position( EXPORTING it_keys     = CORRESPONDING #( keys )
                             iv_delta    = 1
                   IMPORTING et_problems = DATA(problems) ).

    LOOP AT problems INTO DATA(problem).
      APPEND VALUE #( %tky = problem-key-%tky ) TO failed-equistruk.
      APPEND VALUE #( %tky = problem-key-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = problem-text ) )
             TO reported-equistruk.
    ENDLOOP.

  ENDMETHOD.


  METHOD setposition.

    DATA problems     TYPE tt_problems.
    DATA row_problems TYPE tt_problems.

    " Jede Zeile bringt ihre eigene Zielnummer in %param mit, daher einzeln.
    LOOP AT keys INTO DATA(key).

      move_position( EXPORTING it_keys     = VALUE #( ( CORRESPONDING #( key ) ) )
                               iv_target   = key-%param-targetseqnumber
                     IMPORTING et_problems = row_problems ).

      APPEND LINES OF row_problems TO problems.

    ENDLOOP.

    LOOP AT problems INTO DATA(problem).
      APPEND VALUE #( %tky = problem-key-%tky ) TO failed-equistruk.
      APPEND VALUE #( %tky = problem-key-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = problem-text ) )
             TO reported-equistruk.
    ENDLOOP.

  ENDMETHOD.


  METHOD read_plan_rows.

    TYPES: BEGIN OF ty_row_key,
             plantype     TYPE zjmqm_qm009_q-plnty,
             plangroup    TYPE zjmqm_qm009_q-plnnr,
             groupcounter TYPE zjmqm_qm009_q-plnal,
             nodecounter  TYPE zjmqm_qm009_q-zaehl,
             seqnumber    TYPE zjmqm_qm009_q-lfdnr,
           END OF ty_row_key.

    DATA row_keys TYPE SORTED TABLE OF ty_row_key
                  WITH UNIQUE KEY plantype plangroup groupcounter nodecounter seqnumber.

    DATA plan_keys TYPE tt_keys.

    CLEAR et_rows.

    SELECT plnty, plnnr, plnal, zaehl, lfdnr
      FROM zjmqm_qm009_q
      WHERE plnty = @is_key-plantype
        AND plnnr = @is_key-plangroup
        AND plnal = @is_key-groupcounter
        AND zaehl = @is_key-nodecounter
      INTO TABLE @DATA(db_rows).

    LOOP AT db_rows INTO DATA(db_row).
      INSERT VALUE #( plantype     = db_row-plnty
                      plangroup    = db_row-plnnr
                      groupcounter = db_row-plnal
                      nodecounter  = db_row-zaehl
                      seqnumber    = db_row-lfdnr ) INTO TABLE row_keys.
    ENDLOOP.

    LOOP AT it_extra_keys INTO DATA(extra).

      IF extra-plantype     <> is_key-plantype
      OR extra-plangroup    <> is_key-plangroup
      OR extra-groupcounter <> is_key-groupcounter
      OR extra-nodecounter  <> is_key-nodecounter.
        CONTINUE.
      ENDIF.

      INSERT VALUE #( plantype     = extra-plantype
                      plangroup    = extra-plangroup
                      groupcounter = extra-groupcounter
                      nodecounter  = extra-nodecounter
                      seqnumber    = extra-seqnumber ) INTO TABLE row_keys.
    ENDLOOP.

    LOOP AT row_keys INTO DATA(row_key).
      APPEND VALUE #( plantype     = row_key-plantype
                      plangroup    = row_key-plangroup
                      groupcounter = row_key-groupcounter
                      nodecounter  = row_key-nodecounter
                      seqnumber    = row_key-seqnumber ) TO plan_keys.
    ENDLOOP.

    READ ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
      ENTITY equistruk
        ALL FIELDS WITH CORRESPONDING #( plan_keys )
      RESULT et_rows.

    SORT et_rows BY seqnumber ASCENDING.

  ENDMETHOD.


  METHOD move_position.

    CLEAR et_problems.

    LOOP AT it_keys INTO DATA(key).

      read_plan_rows( EXPORTING is_key  = key
                      IMPORTING et_rows = DATA(rows) ).

      " Index der zu verschiebenden Zeile
      DATA(from_index) = 0.
      LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
        IF <row>-seqnumber = key-seqnumber.
          from_index = sy-tabix.
          EXIT.
        ENDIF.
      ENDLOOP.

      CHECK from_index > 0.

      DATA(row_no)   = CONV i( key-seqnumber ).
      DATA(to_index) = 0.

      IF iv_target >= 0.

        LOOP AT rows ASSIGNING <row>.
          IF <row>-seqnumber = iv_target.
            to_index = sy-tabix.
            EXIT.
          ENDIF.
        ENDLOOP.

        IF to_index = 0.
          APPEND VALUE #( key  = VALUE #( %tky = key-%tky )
                          text = |Zeile { row_no }: Nr. { iv_target } gibt es nicht| )
                 TO et_problems.
          CONTINUE.
        ENDIF.

      ELSE.
        to_index = from_index + iv_delta.
      ENDIF.

      IF to_index < 1 OR to_index > lines( rows ).
        APPEND VALUE #( key  = VALUE #( %tky = key-%tky )
                        text = |Zeile { row_no }: bereits am Rand| )
               TO et_problems.
        CONTINUE.
      ENDIF.

      CHECK to_index <> from_index.

      " Zeilen in die neue Reihenfolge bringen ...
      DATA(reordered) = rows.
      DATA(moved)     = rows[ from_index ].
      DELETE reordered INDEX from_index.
      INSERT moved INTO reordered INDEX to_index.

      " ... und den Inhalt unter den unveraenderten Schluesseln ablegen.
      " Geschrieben wird nur der rotierte Bereich.
      DATA(low)  = COND i( WHEN from_index < to_index THEN from_index ELSE to_index ).
      DATA(high) = COND i( WHEN from_index < to_index THEN to_index ELSE from_index ).

      DATA updates TYPE TABLE FOR UPDATE zjmqms_i_equistruk.
      CLEAR updates.

      LOOP AT rows ASSIGNING FIELD-SYMBOL(<target_row>) FROM low TO high.
        DATA(upd) = CORRESPONDING ty_update( reordered[ sy-tabix ] ).
        upd-%tky = <target_row>-%tky.
        APPEND upd TO updates.
      ENDLOOP.

      MODIFY ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
        ENTITY equistruk
          UPDATE FIELDS ( matebene00 matebene01 matebene02 matebene03 matebene04
                          matebene05 matebene06 matebene07 matebene08 matebene09
                          matebene10 matebene11 matebene12 matebene13 matebene14
                          matebene15 matebene16 matebene17 matebene18 matebene19 )
          WITH updates
        REPORTED DATA(update_reported).

    ENDLOOP.

  ENDMETHOD.


  METHOD check_hierarchy.

    TYPES: BEGIN OF ty_plan,
             plantype     TYPE zjmqm_qm009_q-plnty,
             plangroup    TYPE zjmqm_qm009_q-plnnr,
             groupcounter TYPE zjmqm_qm009_q-plnal,
             nodecounter  TYPE zjmqm_qm009_q-zaehl,
           END OF ty_plan.

    TYPES: BEGIN OF ty_row_key,
             plantype     TYPE zjmqm_qm009_q-plnty,
             plangroup    TYPE zjmqm_qm009_q-plnnr,
             groupcounter TYPE zjmqm_qm009_q-plnal,
             nodecounter  TYPE zjmqm_qm009_q-zaehl,
             seqnumber    TYPE zjmqm_qm009_q-lfdnr,
           END OF ty_row_key.

    DATA plans TYPE SORTED TABLE OF ty_plan
               WITH UNIQUE KEY plantype plangroup groupcounter nodecounter.

    DATA row_keys TYPE SORTED TABLE OF ty_row_key
                  WITH UNIQUE KEY plantype plangroup groupcounter nodecounter seqnumber.

    DATA plan_keys TYPE tt_keys.
    DATA key       TYPE ty_key.

    CLEAR et_problems.

    " Betroffene Pruefplaene einsammeln
    LOOP AT it_keys INTO key.
      INSERT VALUE #( plantype     = key-plantype
                      plangroup    = key-plangroup
                      groupcounter = key-groupcounter
                      nodecounter  = key-nodecounter ) INTO TABLE plans.
    ENDLOOP.

    LOOP AT plans INTO DATA(plan).

      CLEAR row_keys.

      " Zeilen aus der Datenbank ...
      SELECT plnty, plnnr, plnal, zaehl, lfdnr
        FROM zjmqm_qm009_q
        WHERE plnty = @plan-plantype
          AND plnnr = @plan-plangroup
          AND plnal = @plan-groupcounter
          AND zaehl = @plan-nodecounter
        INTO TABLE @DATA(db_rows).

      LOOP AT db_rows INTO DATA(db_row).
        INSERT VALUE #( plantype     = db_row-plnty
                        plangroup    = db_row-plnnr
                        groupcounter = db_row-plnal
                        nodecounter  = db_row-zaehl
                        seqnumber    = db_row-lfdnr ) INTO TABLE row_keys.
      ENDLOOP.

      " ... und die in dieser Transaktion neu angelegten
      LOOP AT it_keys INTO key.

        IF key-plantype     <> plan-plantype
        OR key-plangroup    <> plan-plangroup
        OR key-groupcounter <> plan-groupcounter
        OR key-nodecounter  <> plan-nodecounter.
          CONTINUE.
        ENDIF.

        INSERT VALUE #( plantype     = key-plantype
                        plangroup    = key-plangroup
                        groupcounter = key-groupcounter
                        nodecounter  = key-nodecounter
                        seqnumber    = key-seqnumber ) INTO TABLE row_keys.
      ENDLOOP.

      CLEAR plan_keys.
      LOOP AT row_keys INTO DATA(row_key).
        APPEND VALUE #( plantype     = row_key-plantype
                        plangroup    = row_key-plangroup
                        groupcounter = row_key-groupcounter
                        nodecounter  = row_key-nodecounter
                        seqnumber    = row_key-seqnumber ) TO plan_keys.
      ENDLOOP.

      " Liest den Stand inklusive der noch nicht gesicherten Aenderungen.
      " In dieser Transaktion geloeschte Zeilen kommen nicht zurueck.
      READ ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
        ENTITY equistruk
          ALL FIELDS WITH CORRESPONDING #( plan_keys )
        RESULT DATA(rows).

      SORT rows BY seqnumber ASCENDING.

      DATA(previous)   = -1.
      DATA(root_count) = 0.

      LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).

        current_level( EXPORTING is_row   = <row>
                       IMPORTING ev_level = DATA(level) ).

        " Leere Zeilen meldet bereits validaterow
        CHECK level >= 0.

        " Laufende Nummer ohne fuehrende Nullen; sie steht am Anfang jeder
        " Meldung, damit sie die 50-Zeichen-Kappung ueberlebt.
        DATA(row_no) = CONV i( <row>-seqnumber ).

        " Ein Plan hat genau eine Wurzel. Ein zweites Material auf Ebene 0
        " faellt der Sprungregel nicht auf, weil ein Ruecksprung nach oben
        " erlaubt ist - deshalb hier eigens gezaehlt.
        IF level = 0.
          root_count = root_count + 1.
          IF root_count > 1.
            APPEND VALUE #( key  = VALUE #( %tky = <row>-%tky )
                            text = |Zeile { row_no }: zweite Zeile auf Ebene 0| )
                   TO et_problems.
          ENDIF.
        ENDIF.

        IF level > previous + 1.
          APPEND VALUE #(
            key  = VALUE #( %tky = <row>-%tky )
            text = COND string(
                     WHEN previous < 0
                     THEN |Zeile { row_no }: muss auf Ebene 0 liegen|
                     ELSE |Zeile { row_no }: Ebene { level } folgt auf { previous }| ) )
                 TO et_problems.
        ENDIF.

        previous = level.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD einruecken.

    move_level( EXPORTING it_keys     = CORRESPONDING #( keys )
                          iv_delta    = 1
                IMPORTING et_problems = DATA(problems) ).

    LOOP AT problems INTO DATA(problem).
      APPEND VALUE #( %tky = problem-key-%tky ) TO failed-equistruk.
      APPEND VALUE #( %tky = problem-key-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = problem-text ) )
             TO reported-equistruk.
    ENDLOOP.

  ENDMETHOD.


  METHOD ausruecken.

    move_level( EXPORTING it_keys     = CORRESPONDING #( keys )
                          iv_delta    = -1
                IMPORTING et_problems = DATA(problems) ).

    LOOP AT problems INTO DATA(problem).
      APPEND VALUE #( %tky = problem-key-%tky ) TO failed-equistruk.
      APPEND VALUE #( %tky = problem-key-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = problem-text ) )
             TO reported-equistruk.
    ENDLOOP.

  ENDMETHOD.


  METHOD setebene.

    DATA problems     TYPE tt_problems.
    DATA row_problems TYPE tt_problems.

    " Jede Zeile bringt ihre eigene Zielebene in %param mit, daher einzeln.
    LOOP AT keys INTO DATA(key).

      move_level( EXPORTING it_keys     = VALUE #( ( CORRESPONDING #( key ) ) )
                            iv_target   = CONV i( key-%param-ebene )
                  IMPORTING et_problems = row_problems ).

      APPEND LINES OF row_problems TO problems.

    ENDLOOP.

    LOOP AT problems INTO DATA(problem).
      APPEND VALUE #( %tky = problem-key-%tky ) TO failed-equistruk.
      APPEND VALUE #( %tky = problem-key-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = problem-text ) )
             TO reported-equistruk.
    ENDLOOP.

  ENDMETHOD.


  METHOD move_level.

    CLEAR et_problems.

    READ ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
      ENTITY equistruk
        ALL FIELDS WITH CORRESPONDING #( it_keys )
      RESULT DATA(rows).

    DATA updates TYPE TABLE FOR UPDATE zjmqms_i_equistruk.

    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).

      current_level( EXPORTING is_row      = <row>
                     IMPORTING ev_level    = DATA(level)
                               ev_material = DATA(material) ).

      DATA(row_no) = CONV i( <row>-seqnumber ).

      IF level < 0.
        APPEND VALUE #( key  = VALUE #( %tky = <row>-%tky )
                        text = |Zeile { row_no }: keine Materialnummer| )
               TO et_problems.
        CONTINUE.
      ENDIF.

      DATA(target) = COND i( WHEN iv_target >= 0 THEN iv_target
                                                 ELSE level + iv_delta ).

      IF target < 0 OR target > c_max_level.
        APPEND VALUE #( key  = VALUE #( %tky = <row>-%tky )
                        text = |Zeile { row_no }: Ebene { target } gibt es nicht| )
               TO et_problems.
        CONTINUE.
      ENDIF.

      " Alle Ebenenfelder leeren, danach die Zielebene setzen.
      DO c_levels TIMES.
        ASSIGN COMPONENT |MATEBENE{ sy-index - 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
               OF STRUCTURE <row> TO FIELD-SYMBOL(<level_field>).
        IF sy-subrc = 0.
          CLEAR <level_field>.
        ENDIF.
      ENDDO.

      ASSIGN COMPONENT |MATEBENE{ target WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
             OF STRUCTURE <row> TO <level_field>.
      IF sy-subrc = 0.
        <level_field> = material.
      ENDIF.

      APPEND CORRESPONDING #( <row> ) TO updates.

    ENDLOOP.

    CHECK updates IS NOT INITIAL.

    MODIFY ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
      ENTITY equistruk
        UPDATE FIELDS ( matebene00 matebene01 matebene02 matebene03 matebene04
                        matebene05 matebene06 matebene07 matebene08 matebene09
                        matebene10 matebene11 matebene12 matebene13 matebene14
                        matebene15 matebene16 matebene17 matebene18 matebene19 )
        WITH updates
      REPORTED DATA(update_reported).

  ENDMETHOD.


  METHOD current_level.

    ev_level = -1.
    CLEAR ev_material.

    DO c_levels TIMES.
      ASSIGN COMPONENT |MATEBENE{ sy-index - 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
             OF STRUCTURE is_row TO FIELD-SYMBOL(<level_field>).
      CHECK sy-subrc = 0.
      IF <level_field> IS NOT INITIAL.
        ev_level    = sy-index - 1.
        ev_material = <level_field>.
      ENDIF.
    ENDDO.

  ENDMETHOD.


  METHOD get_global_authorizations.

    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'TABLE' FIELD 'ZJMQM_QM009_Q'
      ID 'ACTVT' FIELD '02'.

    DATA(auth) = COND #( WHEN sy-subrc = 0
                         THEN if_abap_behv=>auth-allowed
                         ELSE if_abap_behv=>auth-unauthorized ).

    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = auth.
    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = auth.
    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = auth.
    ENDIF.

  ENDMETHOD.


  METHOD earlynumbering_create.

    TYPES: BEGIN OF ty_max,
             plan_type     TYPE zjmqm_qm009_q-plnty,
             plan_group    TYPE zjmqm_qm009_q-plnnr,
             group_counter TYPE zjmqm_qm009_q-plnal,
             node_counter  TYPE zjmqm_qm009_q-zaehl,
             max_seq       TYPE zjmqm_qm009_q-lfdnr,
           END OF ty_max.

    DATA max_table TYPE SORTED TABLE OF ty_max
                   WITH UNIQUE KEY plan_type plan_group group_counter node_counter.

    LOOP AT entities INTO DATA(entity).

      " Vom Client vorgegebene laufende Nummer respektieren
      IF entity-seqnumber IS NOT INITIAL.
        APPEND VALUE #( %cid = entity-%cid
                        %key = entity-%key ) TO mapped-equistruk.
        CONTINUE.
      ENDIF.

      READ TABLE max_table ASSIGNING FIELD-SYMBOL(<max>)
           WITH TABLE KEY plan_type     = entity-plantype
                          plan_group    = entity-plangroup
                          group_counter = entity-groupcounter
                          node_counter  = entity-nodecounter.

      IF sy-subrc <> 0.
        SELECT MAX( lfdnr ) FROM zjmqm_qm009_q
          WHERE plnty = @entity-plantype
            AND plnnr = @entity-plangroup
            AND plnal = @entity-groupcounter
            AND zaehl = @entity-nodecounter
          INTO @DATA(max_on_db).

        INSERT VALUE #( plan_type     = entity-plantype
                        plan_group    = entity-plangroup
                        group_counter = entity-groupcounter
                        node_counter  = entity-nodecounter
                        max_seq       = max_on_db )
               INTO TABLE max_table ASSIGNING <max>.
      ENDIF.

      <max>-max_seq = <max>-max_seq + 1.

      APPEND VALUE #( %cid         = entity-%cid
                      plantype     = entity-plantype
                      plangroup    = entity-plangroup
                      groupcounter = entity-groupcounter
                      nodecounter  = entity-nodecounter
                      seqnumber    = <max>-max_seq )
             TO mapped-equistruk.

    ENDLOOP.

  ENDMETHOD.


  METHOD normalizematerial.

    READ ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
      ENTITY equistruk
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(rows).

    DATA updates  TYPE TABLE FOR UPDATE zjmqms_i_equistruk.
    DATA material TYPE matnr.

    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).

      DATA(changed) = abap_false.

      DO c_levels TIMES.

        ASSIGN COMPONENT |MATEBENE{ sy-index - 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
               OF STRUCTURE <row> TO FIELD-SYMBOL(<level>).
        CHECK sy-subrc = 0.
        CHECK <level> IS NOT INITIAL.

        CLEAR material.
        CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
          EXPORTING  input        = <level>
          IMPORTING  output       = material
          EXCEPTIONS length_error = 1
                     OTHERS       = 2.

        IF sy-subrc = 0 AND material <> <level>.
          <level> = material.
          changed = abap_true.
        ENDIF.

      ENDDO.

      IF changed = abap_true.
        APPEND CORRESPONDING #( <row> ) TO updates.
      ENDIF.

    ENDLOOP.

    CHECK updates IS NOT INITIAL.

    MODIFY ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
      ENTITY equistruk
        UPDATE FIELDS ( matebene00 matebene01 matebene02 matebene03 matebene04
                        matebene05 matebene06 matebene07 matebene08 matebene09
                        matebene10 matebene11 matebene12 matebene13 matebene14
                        matebene15 matebene16 matebene17 matebene18 matebene19 )
        WITH updates
      REPORTED DATA(update_reported).

  ENDMETHOD.


  METHOD validaterow.

    READ ENTITIES OF zjmqms_i_equistruk IN LOCAL MODE
      ENTITY equistruk
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(rows).

    DATA material TYPE matnr.

    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).

      DATA(filled) = 0.
      CLEAR material.

      " Laufende Nummer ohne fuehrende Nullen, steht am Anfang jeder Meldung
      DATA(row_no) = CONV i( <row>-seqnumber ).

      DO c_levels TIMES.
        ASSIGN COMPONENT |MATEBENE{ sy-index - 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
               OF STRUCTURE <row> TO FIELD-SYMBOL(<level>).
        CHECK sy-subrc = 0.
        IF <level> IS NOT INITIAL.
          filled   = filled + 1.
          material = <level>.
        ENDIF.
      ENDDO.

      IF filled = 0.
        APPEND VALUE #( %tky = <row>-%tky ) TO failed-equistruk.
        APPEND VALUE #( %tky        = <row>-%tky
                        %state_area = 'VALIDATE_ROW'
                        %msg        = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = |Zeile { row_no }: keine Materialnummer erfasst| ) )
               TO reported-equistruk.
        CONTINUE.
      ENDIF.

      IF filled > 1.
        APPEND VALUE #( %tky = <row>-%tky ) TO failed-equistruk.
        APPEND VALUE #( %tky        = <row>-%tky
                        %state_area = 'VALIDATE_ROW'
                        %msg        = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = |Zeile { row_no }: nur eine Ebene darf gefuellt sein| ) )
               TO reported-equistruk.
        CONTINUE.
      ENDIF.

      " Nicht vorhandene Materialien nur melden, nicht blockieren:
      " im Bestand existieren Zeilen mit Materialien ausserhalb von MARA
      SELECT SINGLE @abap_true FROM mara
        WHERE matnr = @material
        INTO @DATA(material_exists).

      " Bewusst OHNE %state_area: State-Messages haengen an der Entitaet und
      " werden nur mit deren Payload uebertragen. Die Aktionen liefern aber
      " 204 ohne Payload - als Transition-Message kommt die Warnung ueber den
      " sap-messages-Header beim Client an.
      IF material_exists <> abap_true.

        " ALPHA = OUT liefert das 40-stellige Feld mit Leerzeichen aufgefuellt.
        " Ohne CONDENSE reisst der Text die 50-Zeichen-Grenze von
        " new_message_with_text und wird abgeschnitten.
        DATA(material_out) = |{ material ALPHA = OUT }|.
        CONDENSE material_out.

        APPEND VALUE #( %tky = <row>-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-warning
                                 text     = |Zeile { row_no }: Material { material_out } fehlt| ) )
               TO reported-equistruk.
      ENDIF.

    ENDLOOP.

    " Ebenenfolge des ganzen Plans pruefen. Nur Warnung: beim Umbauen einer
    " Struktur entstehen zwangslaeufig Zwischenstaende, die noch nicht
    " stimmig sind - die duerfen das Speichern nicht blockieren.
    check_hierarchy( EXPORTING it_keys     = CORRESPONDING #( keys )
                     IMPORTING et_problems = DATA(hierarchy_problems) ).

    LOOP AT hierarchy_problems INTO DATA(hierarchy_problem).
      APPEND VALUE #( %tky = hierarchy_problem-key-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-warning
                               text     = hierarchy_problem-text ) )
             TO reported-equistruk.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
