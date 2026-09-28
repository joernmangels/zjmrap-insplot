# Arbeitsstand

Stand: 28.08.2026 · Fortsetzungspunkt für die nächste Sitzung.
Fachliche und technische Hintergründe stehen in [README.md](README.md);
hier steht nur, **was fertig ist und was noch aussteht**.

---

## Fertig und verifiziert

### Backend — alle Objekte aktiv, keine inaktiven Reste

Paket `ZJMRAP_INSPLOT`, Transportauftrag siehe lokale `ui5-deploy.yaml`.

| Objekt | Typ |
|---|---|
| `ZJMQMS_I_MATERIAL_VH` | DDLS — Wertehilfe/Text aus MARA + MAKT |
| `ZJMQMS_I_EQUISTRUK` | DDLS — Interface View, berechnet `Ebene`/`Material` |
| `ZJMQMS_C_EQUISTRUK` | DDLS — Projection View + `_MatText` |
| `ZJMQMS_I_EQUISTRUK` | BDEF — managed, early numbering, 6 Aktionen |
| `ZJMQMS_C_EQUISTRUK` | BDEF — Projection Behavior |
| `ZJMQMS_BP_EQUISTRUK` | CLAS — Behavior Pool |
| `ZJMQMS_A_SET_EBENE` | DDLS — Aktionsparameter Zielebene |
| `ZJMQMS_A_SET_POSITION` | DDLS — Aktionsparameter Zielposition |
| `ZJMQMS_SD_EQUISTRUK` | SRVD |
| `ZJMQMS_SB_EQUISTRUK` | SRVB — OData V4, **UI**-Binding, publiziert |

Sechs Aktionen im Service verifiziert: `einruecken`, `ausruecken`, `setEbene`,
`nachOben`, `nachUnten`, `setPosition`. Zwanzig Ebenenfelder (`MatEbene00`–`19`).

### Frontend

Freestyle SAPUI5, 18 Dateien. Funktioniert im Browser: Selektion, Anzeige mit
Einrückung, Baum-Konnektor, Farbe je Ebene, Ebene per Pfeil und Direkteingabe,
Zeile vertikal verschieben, Anlegen, Löschen, Meldungsanzeige.

### Ersteinlesung aus dem Prüfplan (28.09.2026)

Knopf „Ersteinlesung" in der Tabellen-Toolbar. Löscht die Zeilen **des
selektierten Plans** und baut sie aus den Vorgangskurztexten neu auf: Material
aus den ersten sieben Stellen, Ebene aus `N. Ebene` im Text, erster Vorgang ist
die Wurzel. Vorgänge ohne Materialnummer werden übersprungen und gemeldet.

Backend: `static action ersteinlesen` (statisch, weil der Plan beim ersten
Einlesen noch keine Zeile hat), Parameter `ZJMQMS_A_ERSTEINLESUNG`, Ergebnis
`ZJMQMS_A_EINLESEN_ERG` mit `Deleted`/`Created`/`Skipped`. Vorgänge kommen über
PLKO → PLAS → PLPO, am Planzähler verankert.

Sonde `ZJMQMS_CL_PROBE_EINLES` (`$TMP`, HARMLESS, ohne `COMMIT ENTITIES`) grün:
Plan Q/00000004/02 → 7 gelöscht, 7 angelegt, 4 übersprungen.

**Im Browser noch nicht getestet.**

### Prüfungen

- genau ein Ebenenfeld je Zeile (Fehler)
- Material nicht im Materialstamm (Warnung)
- Ebenensprung höchstens +1 gegenüber der Vorgängerzeile (Warnung)
- nur eine Zeile auf Ebene 0 je Plan (Warnung)

Alle Meldungen beginnen mit `Zeile <n>:`.

### Tests

`ZJMQMS_CL_PROBE` (Paket `$TMP`, **nicht** im Transport), 4 ABAP-Unit-Tests grün:
`TEMPLATE_NAMES`, `ROW_LEVEL_FIELDS`, `HIERARCHY_GAP_ERKANNT`,
`ZWEITE_WURZEL_ERKANNT`.

---

## Offen

### 1 · Metadata Extension anlegen

`ZJMQMS_MC_EQUISTRUK` fehlt noch im System. Quelle liegt in
[`abap/ZJMQMS_MC_EQUISTRUK.asddlxs`](abap/ZJMQMS_MC_EQUISTRUK.asddlxs), Anleitung
im README. Über die ADT-Schreib-API nicht anlegbar — DDLX wird nicht unterstützt.

Wirkt nur auf die ADT-Service-Vorschau und Fiori Elements, **nicht** auf die
freestyle-App.

### 2 · Frontend nach GitHub — erledigt, aber Nachzügler offen

Der erste Push ist erfolgt: **dasselbe Repo wie die ABAP-Objekte**, Frontend im
Unterordner **`ui5_equi_struk/`**, Repo **öffentlich**.

Der Namensraum `de.enercon.qm009.equistruk` war zu diesem Zeitpunkt bereits
umgestellt und ist mit im ersten Commit.

Aus der abapGit-Ablage im System ausgelesen:

| | |
|---|---|
| Repository | `https://github.com/joernmangels/zjmrap-insplot.git` |
| Branch | `main` |
| Paket | `ZJMRAP_INSPLOT` |
| `STARTING_FOLDER` | `/src/` — abapGit fasst nur diesen Ordner an |

Deshalb bereits erledigt:
- `.gitignore` schließt `node_modules/`, `ui5.yaml`, `ui5-deploy.yaml` aus
- Vorlagen `ui5.yaml.example` und `ui5-deploy.yaml.example` angelegt
- README von Hostname, Mandant und Transportnummer befreit

Noch zu tun: Repo klonen, `ui5_equi_struk/` befüllen, committen, pushen.
Befehlsfolge stand im Chat.

### 3 · Launchpad-Konfiguration im Zielsystem

Vorbereitet, aber im System **nicht durchgeführt** — über die ADT-Schnittstelle
nicht erreichbar. Anleitung mit allen konkreten Werten:
[LAUNCHPAD.md](LAUNCHPAD.md).

Die App bringt den Inbound `ZEquiStruktur-maintain` im Manifest bereits mit;
Semantisches Objekt, Ziel-Mapping, Kachel, Gruppe und Rollenzuordnung sind
Handarbeit im Zielsystem.

### 4 · Backend ins Zielsystem bringen

Das Deployment bringt nur das Frontend. Im Kundensystem müssen vorher existieren:
Tabelle `ZJMQM_QM009_Q` samt Datenelementen, alle `ZJMQMS_*`-Objekte und das
publizierte Service Binding. Weg: Transport oder abapGit-Pull aus demselben
Repository.

Danach `ui5-deploy.yaml` aus der Vorlage erzeugen (Host, Mandant, Paket,
Transport des Zielsystems) und `npm run deploy-test`, dann `npm run deploy`.

---

## Report „Equipment-Struktur aus Prüflos" (VID-200, seit 14.09.2026)

Plan: `~/.claude/plans/mach-dir-mal-gedanken-parsed-finch.md`. Alle Objekte aktiv
und im Transport `VIDK901614`.

| Objekt | Typ | Aufgabe |
|---|---|---|
| `ZJMQMS_CL_LOT_EQUI` | CLAS | QALS, `ZJMQM_QM009_E`, Vorgänge (`I_InspectionOperation`), Serialnummer aus QASE, Equipment suchen/anlegen (`ZJMQM009_ASGN_SERNR_PL_2`) |
| `ZJMQMS_CL_EQUI_STRUKTUR` | CLAS | Soll-Struktur aus `ZJMQMS_I_EQUISTRUK`, `resolve_parents`, `assign_equipments`, Einbau per `BAPI_EQUI_INSTALL` |
| `ZJMQMS_R_EQUI_STRUKTUR` | PROG | `s_plos` (Pflicht), `s_werk`, `s_datum`, `p_test` (Vorbelegung X), ALV-Protokoll |

Unit-Tests: `ZJMQMS_CL_EQUI_STRUKTUR` → `LTC_RESOLVE_PARENTS` (5),
`LTC_ASSIGN_EQUIPMENTS` (5), `LTC_PARENT_FOR_CHILD` (3), alle grün. Quellen
gespiegelt in `abap/`.

**Zuordnung Strukturzeile → Equipment (17.09.2026, zweimal auf Wunsch geändert):**
Eine Strukturzeile ist eine Vorlage und bekommt **alle** Equipments ihres
Materials aus dem Los (drei Vorgänge mit 1076809 → drei Equipments an dieser
Stelle). Beim Einbau zwischen Kind- und Elternzeile gilt 1:n (ein
Eltern-Equipment nimmt alle Kinder) oder n:n (paarweise in Vorgangsreihenfolge);
sonst Fehler „Zuordnung unklar". Dieselbe Regel, wenn ein Material mehrfach in
der Struktur steht. Eindeutig sein muss nur Material + Serialnummer im Los.

Erster Testlauf (Los 940005101311, Plan Q 50009564/1) hat die
Serialnummern-Ermittlung aus QASE bestätigt: alle 7 Vorgänge mit Material
liefern Serialnummer, Equipment 53138275 zum Kopfmaterial bereits vorhanden.

### Offen

1. **Test-Include für `ZJMQMS_CL_LOT_EQUI`** ließ sich über die Schnittstelle
   nicht anlegen (Klasse existierte schon, CCAU nicht). Quelle liegt in
   [`abap/ZJMQMS_CL_LOT_EQUI.clas.testclasses.abap`](abap/ZJMQMS_CL_LOT_EQUI.clas.testclasses.abap)
   → in Eclipse Reiter *Test Classes* einfügen, aktivieren, ausführen.
2. **Selektionstexte** des Reports (S_PLOS, S_WERK, S_DATUM, P_TEST) fehlen —
   `SetTextElements` braucht WebSocket, den das System nicht bietet. In SE38
   → Textelemente → Selektionstexte nachpflegen. Rahmentitel sind im Code.
3. **Testlauf im Testmodus** auf einem Los mit Serialnummern. Entscheidet die
   drei Risiken des Bausteins `ZJMQM009_ASGN_SERNR_PL_2` (Profil Z001,
   SER04 für Untermaterialien, entsteht ein EQUI-Satz?).
4. Echtlauf, Wiederholungslauf (alle Zeilen „vorhanden").

---

## Erledigt seit der letzten Sicherung

- Namensraum von `de.varelmann.qm.equistruk` auf **`de.enercon.qm009.equistruk`**
  umgestellt, 13 Stellen in 6 Dateien, gegen den laufenden Server verifiziert.
- `index.html` lädt UI5 jetzt über `/sap/public/bc/ui5_ui5/resources/sap-ui-core.js`
  statt relativ — der relative Pfad hätte im deployten BSP einen 404 ergeben.
  Der ABAP-Server liefert UI5 **1.136.21**, alle benötigten Module vorhanden.
- Launchpad-Inbound `ZEquiStruktur-maintain` im Manifest, Kacheltexte in i18n.

---

## Bekannte Randbedingungen

- **Verwaiste Materialien.** Ein Teil der Bestandszeilen verweist auf
  Materialien, die in MARA nicht existieren. Sie erscheinen ohne Kurztext, beim
  Speichern kommt eine Warnung. Kein Anwendungsfehler.
- **Teilbaum-Verschiebung fehlt.** `nachOben`/`nachUnten` bewegen nur die eine
  Zeile, nicht ihre Unterzeilen. Bewusst so zugeschnitten.
- **Reihenfolge ändert die Schlüssel nicht.** Verschoben wird der Inhalt, die
  `LFDNR` bleibt stehen.

---

## Umgebung

- Entwicklungsserver lief unter `http://localhost:8080` (`npx ui5 serve`).
  Nach Sitzungsende beendet — mit `npm start` neu starten.
- `ui5.yaml` und `ui5-deploy.yaml` existieren lokal mit den echten Systemdaten,
  sind aber vom Repository ausgeschlossen.
- `gh` (GitHub CLI) ist **nicht** installiert; Repo-Anlage über die Weboberfläche.

### Grenzen der ADT-Schnittstelle in diesem System

Beim Weiterarbeiten relevant:

- **DDLX** lässt sich nicht schreiben (`Unsupported object type`).
- **`RunReport`** braucht den ZADT_VSP-Handler — nicht installiert.
- **ABAP-Unit-Tests mit `RISK LEVEL DANGEROUS`** werden nicht ausgeführt.
- **`EditSource`** speichert schon bei Warnungen nicht; dann `WriteSource` mit
  vollem Quelltext nehmen.
- Methodendeklaration und -implementierung müssen **in einem** `EditSource`-Aufruf
  entstehen, sonst schlägt die Prüfung fehl.
- Die Feature-Erkennung (`GetFeatures`) ist unbrauchbar: sie sondiert mit HTTP
  OPTIONS, was dieses System ablehnt, und meldet alles als nicht verfügbar.
