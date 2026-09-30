# Lernprojekt: Fiori-App „Equipment-Struktur aufbauen"

App 2 zum Report `ZJMQMS_R_EQUI_STRUKTUR`. **Ziel ist das Lernen**: Jörn baut
jeden Schritt selbst, Claude erklärt, gibt Gerüste und prüft das Ergebnis.
Claude schreibt nur auf ausdrückliche Bitte Code ins System.

System VID-200, Paket `ZJMRAP_INSPLOT`, Transport `VIDK901629`.
**Fachlicher Test im Kundensystem:** Jörn baut die Objekte dort nach und testet
dort (VID hat keine passenden Lose, z. B. fehlt 940005101311).

---

## Wozu das Ganze

Der Report legt zu einem Prüflos Serialnummern und Equipments an und baut sie
nach der Soll-Struktur aus `ZJMQM_QM009_Q` ineinander ein. Bisher läuft das nur
über SE38 mit ALV-Liste. Die App soll: Lose suchen, Lauf simulieren oder scharf
ausführen, Protokoll ansehen — und die Läufe dauerhaft nachvollziehbar machen.

---

## Die eine harte Randbedingung

Beide Klassen **committen** (`BAPI_TRANSACTION_COMMIT` beim Einbau; der
Anlage-Baustein `ZJMQM009_ASGN_SERNR_PL_2` committet selbst). In einer
RAP-Aktion ist `COMMIT WORK` verboten → Dump `BEHAVIOR_ILLEGAL_STATEMENT`.

**Lösung:** Ein RFC-fähiger Baustein führt den Lauf in **eigener LUW** aus
(`CALL FUNCTION ... DESTINATION 'NONE'`), schreibt das Protokoll und committet
dort. Die RAP-Aktion ruft ihn nur auf und gibt die Lauf-ID zurück. Die App liest
das Protokoll danach als ganz normale OData-Entität.

```
Frontend (freestyle UI5)         OData V4 (RAP)                Klassik
───────────────────────────      ────────────────────────      ────────────────────────
Losliste  ──GET──────────────▶  ZJMQMS_I_LOT (CDS auf QALS)
  ▼ Auswahl + Simulieren/
    Aufbauen
          ──POST action───────▶  aufbauen(Testmodus) ──RFC NONE──▶ ZJMQMS_RUN_STRUKTUR
                                 ◀── RunId ──                       ├ ZJMQMS_CL_LOT_EQUI
Protokoll ──GET $filter RunId─▶  ZJMQMS_I_STRUKLOG (CDS)            ├ ZJMQMS_CL_EQUI_STRUKTUR
                                                                    └ INSERT ZJMQMS_STRUKLOG
                                                                      COMMIT WORK
```

---

## Objekte

| Objekt | Typ | Aufgabe |
|---|---|---|
| `ZJMQMS_STRUKLOG` | TABL | Protokoll. Schlüssel `MANDT`, `RUN_ID` (sysuuid_x16), `SEQ` (int4); dazu `PRUEFLOS`, `TESTMODE`, `STEP` c5, `VORNR`, `MATNR`, `SERNR`, `EQUNR`, `ACTION` c20, `STATUS` c1, `MSG` c255, `CREATED_BY`, `CREATED_AT` |
| `ZJMQMS_RUN_STRUKTUR` | FUNC in FUGR `ZJMQMS_STRUK` | RFC-fähig. `IMPORTING iv_prueflos, iv_test EXPORTING ev_run_id`. Ruft beide Klassen, schreibt Log, `COMMIT WORK` |
| `ZJMQMS_I_LOT` | DDLS | View Entity auf `qals` + Materialtext |
| `ZJMQMS_I_STRUKLOG` | DDLS | View Entity auf `zjmqms_struklog`, Association `_Lot` |
| `ZJMQMS_A_AUFBAU` | DDLS abstract | Aktionsparameter `Echtlauf` (leer = Simulation) |
| `ZJMQMS_A_RUN` | DDLS abstract | Aktionsergebnis `RunId` |
| `ZJMQMS_I_LOT` | BDEF | `unmanaged`, nur `read` + `action aufbauen` |
| `ZJMQMS_BP_LOT` | CLAS | Handler: `read`, `aufbauen` (RFC-Aufruf) |
| `ZJMQMS_I_WERK_VH` | DDLS | Wertehilfe Werk (`t001w`), `@Search` |
| `ZJMQMS_I_PRUEFART_VH` | DDLS | Wertehilfe Prüfart (`tq30` + `tq30t`), `@Search` |
| `ZJMQMS_I_MAT_VH` | DDLS | Wertehilfe Material (`mara` + `makt`), eigene statt der aus App 1 (dort gesperrt in VIDK901614, und App 2 soll ohne App 1 laufen) |
| `ZJMQMS_SD_STRUKRUN` / `ZJMQMS_SB_STRUKRUN` | SRVD/SRVB | OData V4, **UI**, publizieren. Exponiert `Lot`, `StrukLog`, `WerkVH`, `PruefartVH`, `MaterialVH` |

Frontend: `ui5_struk_run/`, Namensraum `de.enercon.qm009.strukrun`.
Der Report bleibt unverändert.

---

## Fortschritt

### Teil A — Backend

- [x] **1 · Tabelle `ZJMQMS_STRUKLOG`** — aktiv seit 23.09.2026 (von Claude angelegt)
      *Lernstoff: Log-Design mit Lauf-ID statt fortlaufender Nummer.*
      Prüfung: Tabelle aktiv, SE16 leer.
- [x] **2 · FM `ZJMQMS_RUN_STRUKTUR`** (FUGR `ZJMQMS_STRUK`, remotefähig)
      — aktiv seit 23.09.2026 (von Claude angelegt). **SE37-Test steht noch aus.**
      Logik aus `lcl_report->process_lot` übernehmen, Log schreiben, committen.
      *Lernstoff: warum eigene LUW; RFC braucht DDIC-Typen.*
      Prüfung: SE37 mit Los 940005101311, `iv_test = X` → Zeilen + RunId.
- [x] **3 · CDS `ZJMQMS_I_LOT` und `ZJMQMS_I_STRUKLOG`** — aktiv seit
      23.09.2026 (von Claude angelegt), Abfrage auf `ZJMQMS_I_LOT` liefert
      Lose mit Materialtext. **Achtung:** Los 940005101311 gibt es in VID-200
      nicht (höchstes Los dort 040000000000) — Testlos für Schritt 2 klären.
      *Lernstoff: View Entity, Textassoziation, `@Search`.*
      Prüfung: Data Preview in ADT.
- [x] **4 · Abstract Entities, BDEF unmanaged, Handler `ZJMQMS_BP_LOT`**
      — aktiv seit 23.09.2026 (von Claude angelegt). `ZJMQMS_I_LOT` ist dafür
      `root view entity` geworden. Sonde `ZJMQMS_CL_PROBE_LOT` ($TMP, Unit-Test)
      mit Los 010000000104 simuliert: RunId zurück, Logzeile trotz
      `ROLLBACK ENTITIES` vorhanden → **Risiko 1 erledigt.**
      *Lernstoff: unmanaged RAP, Aktionsparameter und -ergebnis, `reported`.*
      Prüfung: Sonde in `$TMP` mit EML `MODIFY ENTITIES … EXECUTE aufbauen`.
      **Hier entscheidet sich Risiko 1.**
- [x] **5 · SRVD + SRVB (V4, UI), publizieren** — SRVB von Jörn angelegt,
      V4, publiziert (25.09.2026). `ACTION_NS` per `$metadata` bestätigt
      (localService/mainService/metadata.xml des generierten Projekts).
      SRVD `ZJMQMS_SD_STRUKRUN`
      aktiv (Lot, StrukLog). **SRVB von Hand in ADT anlegen** (Werkzeug
      scheitert). Vorher in `ZJMQMS_I_STRUKLOG` `vornr` → `abap.char(4)` und
      `sernr` → `abap.char(18)` casten: Exits NUMCV/GERNR kennt OData V4 nicht. Erwartet nach Muster App 1:
      URI `/sap/opu/odata4/sap/zjmqms_sb_strukrun/srvd/sap/zjmqms_sd_strukrun/0001/`,
      `ACTION_NS = "com.sap.gateway.srvd.zjmqms_sd_strukrun.v0001."`
      Prüfung: `$metadata` aufrufen, Namespace notieren → wird `ACTION_NS`.
- [x] **6 · Service ohne UI testen** (`/Lot?$top=5`, `/StrukLog?$filter=…`)
      — 25.09.2026 über den Dev-Proxy: Lot mit MaterialText, `$search` 200,
      StrukLog-Filter auf GUID liefert die Sondenzeile. `Prueflos` kommt
      ohne führende Null (ALPHA OUT: `10000000104`).

### Teil B — Frontend

- [x] **7 · Projekt anlegen** (Fiori-Generator, Freestyle, OData V4)
      — 25.09.2026, Template Basic. `ui5.yaml`/`ui5-local.yaml` ignoriert,
      Vorlagen als `.example`. `npm start` öffnet die FLP-Vorschau
      (`test/flp.html`), `start-mock` läuft ohne Backend.
- [x] **8 · Routing** — zwei Views `LotList` und `RunLog`, Routen
      `RouteLotList` (`:?query:`) und `RouteRunLog` (`run/{RunId}`), Deep-Link
      geht. *Offen, bewusst zurückgestellt:* `onNavBack` nutzt nur
      `navTo(…, true)`; besser `History.getPreviousHash()` → `history.go(-1)`,
      sonst `navTo` (vermeidet doppelten Listeneintrag in der Historie).
- [x] **9 · Losliste** — Tabelle mit `growing`, Mehrfachauswahl, eigene
      Filterleiste (Prüflos, Werk, Prüfart, Material, Datumsbereich).
      — 25.09.2026 von Claude gebaut, Abfragen per Proxy getestet; dazu
      Wertehilfen (`SelectDialog` je Feld, Suche per `$search`, Material-
      nummer per `$filter`). Browser-Test durch Jörn ok, `autoExpandSelect`
      im `$batch` als `$select` nachvollzogen.
- [x] **10 · Aktion aufrufen** — 28.09.2026 von Claude gebaut. Simulation
      über den Dev-Proxy gegen VID getestet (Los 10000000104 → RunId).
      Rückfrage mit Losnummer, „Abbrechen" vorbelegt. Echtlauf nur im
      Kundensystem. — „Simulieren" / „Aufbauen" (mit Rückfrage),
      `bindContext(ACTION_NS + "aufbauen(...)", oLotContext)`, Parameter
      `Echtlauf` (nur „Aufbauen" setzt `true`), RunId aus dem Ergebnis,
      danach `navTo("RouteRunLog")`.
      **Entscheidung 28.09.2026: ein Prüflos je Lauf.** Tabelle auf
      Einfachauswahl, keine Schleife im Frontend. Gründe: Route kennt genau
      eine RunId, Rückfrage beim Echtlauf bezieht sich auf genau ein Los,
      Backend bleibt unverändert. Mehrere Lose unter einer RunId (Variante B)
      bräuchte `iv_run_id` im Baustein und fortlaufende `SEQ` über Lose —
      erst nachrüsten, wenn die Nutzer es wirklich brauchen. Alternative für
      die Übersicht: Protokoll aller Läufe zu einem Los (Filter `Prueflos`).
- [x] **11 · Protokollansicht** — 28.09.2026 von Claude gebaut. Kopf per
      `bindElement` auf `StrukLog(RunId=…,Seq=1)` mit `$expand=_Lot`,
      Simulation/Echtlauf als `ObjectStatus`; Tabelle `suspended`, Filter
      auf RunId im Controller; `model/formatter.js` mit `statusState`/
      `statusIcon`. Unbekannte RunId → 404 → Hinweis statt Kopf. Abfragen
      per Proxy gegen VID geprüft.
      *Für Schritt 12:* `Meldung` enthält Leerzeichen aus dem Backend
      (Material ungekürzt im Text) — im Baustein `CONDENSE` bzw. `ALPHA OUT`.
      — Kopf + Tabelle, Status als `ObjectStatus`
      mit Formatter (S → Success, W → Warning, E → Error).
- [x] **11b · Aufbewahrung der Läufe** — 28.09.2026. **Entscheidung:**
      Echtläufe bleiben dauerhaft in `ZJMQMS_STRUKLOG` (Nachweis),
      Simulationen nur die letzte je Los — der Baustein löscht vor dem
      `INSERT` die alten Simulationszeilen des Loses (gleiche LUW, kein Job).
      Per Proxy geprüft: zwei Simulationen hintereinander → nur die neueste
      bleibt, Echtlauf bleibt.
      **Laufübersicht je Los in der App: gebaut und auf Wunsch wieder
      ausgebaut** (Jörn will die Läufe nicht anzeigen). CDS
      `ZJMQMS_I_STRUKRUN` gelöscht, aus der SRVD entfernt; Route, View und
      Knopf entfernt. Die App zeigt nur das Protokoll des gerade gestarteten
      Laufs; ältere Läufe nur über SE16 oder Deep-Link `#/run/<RunId>`.
      Nebenbei erledigt aus Schritt 8: `onNavBack` in `RunLog` nutzt
      `History` → `history.go(-1)`, sonst `navTo` zur Liste.
- [x] **12 · Feinschliff** — 28.09.2026 von Claude. Zähler über Losliste
      und Protokoll (`updateFinished` → `total`), `supportedLocales`/
      `fallbackLocale` im Manifest (keine Build-Warnung, kein Nachladen von
      `i18n_en`), überflüssige `async`-Flags raus. Meldungstexte zentral in
      `add_log` beider Klassen bereinigt (Leerzeichen vor Satzzeichen weg,
      `condense`), Transport `VIDK901614`, 13 Unit-Tests grün.
      **Bewusst offen:** Manifest Version 2 und `minUI5Version` 1.136
      (UI5-Linter-Fehler) — erst, wenn die UI5-Version im Kundensystem
      bekannt ist; VID hat 1.136.21.
      — ursprünglich: **Feinschliff** — Zähler, Sortierung, i18n, Busy, leere Zustände.
- [x] **12b/12c umgesetzt 30.09.2026 (VID)** — Seite auf `sap.f.DynamicPage`,
      Filterleiste `sap.ui.comp.filterbar.FilterBar` mit
      `SmartVariantManagement` im Titel, Varianteninhalt über
      `registerFetchData`/`registerApplyData` (Filterwerte + Sortierung).
      Zusätzliche Filter Charge, Herkunft (über „Filter anpassen").
      Sortierung per `ViewSettingsDialog` (Fragment `SortDialog`), serverseitig.
      Liste `suspended` bis die Standardvariante angewendet ist. Geprüft:
      Seite rendert (Edge headless), Flex-Dienst wird gelesen
      (`/sap/bc/lrep/flex/data/de.enercon.qm009.strukrun`), Filter Herkunft
      im Service ok. **Offen:** Variante speichern/teilen im Browser testen.
      Werk-Vorbelegung aus SU3 bewusst weggelassen (Standardvariante reicht).
      Datum per `DynamicDateRange`: in der Variante steht die Regel
      (`{operator: "LASTDAYSINCLUDED", values: [30]}`), umgerechnet wird erst
      beim Suchen (`DynamicDateRange.toDates`). `LASTDAYSINCLUDED` statt
      `LASTDAYS`, weil Letzteres heute ausschließt — in UI5 1.136 gemessen.
      Bekannte Grenze: Charge nur exakt mit führenden Nullen.
- [ ] **12b · Varianten für die Filterleiste** (Kundenwunsch 30.09.2026:
      „Wieso muss ich immer dieselben Daten eingeben?") — nach der
      Installation im Kundensystem. Eigene Filterleiste durch
      `sap.ui.comp.filterbar.FilterBar` mit `VariantManagement` ersetzen:
      benannte Varianten, Standardvariante, für alle freigebbar, gespeichert
      im Flex-Dienst (LREP) je Benutzer. Zusätzlich Werk aus dem
      Benutzerparameter vorbelegen (SU3, z. B. `WRK`). Kein Backend nötig.
- [ ] **12c · Sortieren und Filtern in der Losliste** (Kundenwunsch
      30.09.2026) — Spalten sortier- und filterbar, z. B. per
      Tabellen-Personalisierung (`sap.m.p13n.Engine`) oder
      `ViewSettingsDialog`; mit 12b abstimmen, damit Sortierung und
      Spaltenauswahl in der Variante mitgespeichert werden.
- [x] **13 · Deployment** nach VID, BSP `ZJMQMS_STRUKRUN` — 28.09.2026,
      Paket `ZJMRAP_INSPLOT`, Transport `VIDK901629`, Anwendungsindex
      aktualisiert. Aufruf `/sap/bc/ui5_ui5/sap/zjmqms_strukrun/index.html`
      (Mandant 200). Vorher `index.html` auf absolutes UI5
      (`/sap/public/bc/ui5_ui5/resources/`) umgestellt, Skripte `deploy` und
      `deploy-test` wie in App 1, Vorlage `ui5-deploy.yaml.example`.
- [ ] **14 · GitHub** — commit und push.

---

## Was wir aus App 1 übernehmen

Liegt daneben in [`../ui5_equi_struk/`](../ui5_equi_struk/):

| Von dort | Wofür |
|---|---|
| `webapp/controller/Main.controller.js` → `_execAction` | Muster für Aktionsaufruf in OData V4 |
| `webapp/controller/Main.controller.js` → `onSearch` | Filter aus Eingabefeldern bauen |
| `webapp/view/Messages.fragment.xml` | unverändert kopieren |
| `webapp/model/formatter.js` | erweitern um `statusState()` |
| `.gitignore`, `*.example`, `package.json` | Projektgerüst |
| `webapp/index.html` | Bootstrap über `/sap/public/bc/ui5_ui5/resources/` |

---

## Risiken

1. ~~**RFC `DESTINATION 'NONE'` aus der RAP-Aktion.**~~ Erledigt 23.09.2026:
   funktioniert, per EML-Sonde gemessen (Schritt 4).
2. **Laufzeit.** Ein Lauf kann Sekunden dauern, die Aktion blockiert so lange.
   Busy-Indicator ist Pflicht. Durch die Einfachauswahl (Schritt 10) läuft
   ohnehin nur ein Los je Aufruf.
3. **`ACTION_NS` steht fest im Controller** — wie in App 1. Beim Kunden heißt
   der Service anders, dann muss die Konstante angepasst werden.
4. **Offen aus dem Report:** Profil Z001 fehlt in T377P, SER04 für
   Untermaterialien ungeklärt. Zeigt sich beim ersten Echtlauf.

---

## Verifikation am Ende

1. Los 940005101311 über die Filter finden
2. „Simulieren" → Protokoll mit 7 EQUI-Zeilen und den STRUK-Zeilen
   (dreimal 1076809 „würde eingebaut"), keine Datenänderung außer dem Log
3. `ZJMQMS_STRUKLOG`: ein Lauf mit `TESTMODE = X`
4. „Aufbauen" → Rückfrage → Lauf → „angelegt" / „eingebaut"
5. Wiederholter Lauf: alles „vorhanden" / „bereits eingebaut"
6. `IE03` auf dem Wurzel-Equipment: Struktur sichtbar
7. Reload auf `#/run/<RunId>`: Seite lädt eigenständig (Deep-Link)
