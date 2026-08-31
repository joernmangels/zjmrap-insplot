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

### 2 · Frontend nach GitHub

Vorbereitet, aber noch nicht ausgeführt. Entschieden war:
**dasselbe Repo wie die ABAP-Objekte** (dort schon per abapGit), Frontend als
Unterordner **`ui5_equi_struk/`**, Repo **öffentlich**.

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

### 3 · Namensraum ggf. neutralisieren

`de.enercon.qm009.equistruk` steht in Manifest, Component, Views und Controller.
Bei einem öffentlichen Repo sichtbar. Umbenennung wäre eine Änderung an sechs
Stellen — bewusst offen gelassen.

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
