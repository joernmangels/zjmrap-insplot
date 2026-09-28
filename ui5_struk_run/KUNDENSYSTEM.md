# Installation im Kundensystem

App 2 „Equi-Struktur aufbauen" komplett ins Kundensystem bringen: Backend,
Service, Frontend, Launchpad, Rolle. Abhaken von oben nach unten — jede Phase
setzt die vorige voraus.

Hostname, Mandant und Transporte des Kundensystems stehen **nicht** in dieser
Datei (das Repository ist öffentlich).

---

## Namen im Kundensystem

Regel: `ZJMQMS_` → `/ENERCON/QM009_`, mit diesen Ausnahmen:

| VID | Kunde | Warum abweichend |
|---|---|---|
| `ZJMQMS_CL_EQUI_STRUKTUR` | `/ENERCON/QM009_CL_EQUI_STRUK` | 30 Zeichen Grenze |
| `ZJMQMS_STRUKLOG` | `/ENERCON/QM009_L` | 16 Zeichen Grenze für Tabellen |
| `ZJMQMS_RUN_STRUKTUR` | `/ENERCON/QM009_STRUK_RUN` | Vorgabe |

**Annahmen — vor dem Aktivieren prüfen** (Objekte, die nicht zu App 2 gehören):

| VID | angenommen beim Kunden | wo benutzt |
|---|---|---|
| `ZJMQM_QM009_Q` | `/ENERCON/QM009_Q` | `03_…CL_EQUI_STRUK` (Feld `LFDNR`) |
| `ZJMQM_QM009_E` | `/ENERCON/QM009_E` | `02_…CL_LOT_EQUI` (Felder `SERNR_HEAD_VORG`, `SERNR_HEAD_MERKMAL` u. a.) |
| `ZJMQMS_I_EQUISTRUK` | `/ENERCON/QM009_I_EQUISTRUK` | `03_…CL_EQUI_STRUK` |
| `ZJMQM009_ASGN_SERNR_PL_2` | **unbekannt** — Platzhalter `<<KUNDENNAME_ASGN_SERNR_PL_2>>` | `02_…CL_LOT_EQUI`, Zeile 454 |

Heißt eines davon anders: in der Quelldatei ersetzen, bevor sie ins System geht.

---

## Phase 2 · Backend anlegen

Quelltexte in [`abap_kunde/`](abap_kunde/), schon auf die Kundennamen
umgestellt und mit allen Änderungen bis 28.09.2026. Je Datei: Objekt in ADT
anlegen, Inhalt komplett ersetzen, aktivieren. **Die Nummer im Dateinamen ist
die Reihenfolge.** Existiert ein Objekt schon, trotzdem den ganzen Inhalt
ersetzen — dann sind auch die Änderungen seit dem 25.09. drin.

- [ ] **01 · Tabelle `/ENERCON/QM009_L`** — `01_TABL_QM009_L.txt`
      ADT: *New → Database Table*. Nur Standard-Datenelemente, nichts weiter zu tun.
- [ ] **02 · Klasse `/ENERCON/QM009_CL_LOT_EQUI`** — `02_…abap`, Reiter
      *Test Classes*: `02_…testclasses.abap`.
      **Vorher** den Platzhalter `<<KUNDENNAME_ASGN_SERNR_PL_2>>` durch den
      Kundennamen des Anlage-Bausteins ersetzen.
      Die Testklassen dieser Klasse liefen auch in VID nie (Test-Include ließ
      sich dort nicht anlegen) — wenn sie nicht aktivieren, weglassen.
- [ ] **03 · Klasse `/ENERCON/QM009_CL_EQUI_STRUK`** — `03_…abap`, Reiter
      *Test Classes*: `03_…testclasses.abap`. Danach Unit-Tests laufen lassen
      (13 Tests, alle grün erwartet).
- [ ] **04 · Funktionsgruppe `/ENERCON/QM009_STRUK`**, darin **Baustein
      `/ENERCON/QM009_STRUK_RUN`** — `04_FUNC_…abap`.
      **Wichtig:** in den Eigenschaften des Bausteins *Remote-Enabled* (RFC)
      setzen. Ohne das scheitert der Aufruf aus der RAP-Aktion.
- [ ] **05 · Abstract Entities** `/ENERCON/QM009_A_AUFBAU`, `/ENERCON/QM009_A_RUN`
- [ ] **06 · Wertehilfen** `/ENERCON/QM009_I_WERK_VH`, `…_I_PRUEFART_VH`, `…_I_MAT_VH`
- [ ] **07 · CDS** zuerst `/ENERCON/QM009_I_LOT`, dann `/ENERCON/QM009_I_STRUKLOG`
      (hat eine Association auf `I_LOT`)
- [ ] **08 · Behavior Definition** zu `/ENERCON/QM009_I_LOT` — `08_…asbdef`
- [ ] **09 · Handler `/ENERCON/QM009_BP_LOT`** — Hauptteil `09_…abap`, Reiter
      *Local Types*: `09_…locals_imp.abap`. Enthält den RFC-Aufruf
      `CALL FUNCTION '/ENERCON/QM009_STRUK_RUN' DESTINATION 'NONE'`.
- [ ] **10 · Service Definition `/ENERCON/QM009_SD_STRUKRUN`** — `10_…srvdsrv`
- [ ] **11 · Service Binding `/ENERCON/QM009_SB_STRUKRUN`** — von Hand:
      *OData V4 - UI*, Service Definition aus 10, aktivieren, **Publish**.
- [ ] *(optional)* **99 · Report** `/ENERCON/QM009_R_EQUI_STRUKTUR` — nur,
      wenn der Report beim Kunden gebraucht wird; die App braucht ihn nicht.

## Phase 3 · Service ohne UI prüfen

- [ ] Im Service Binding die **Service-URL** notieren. Erwartet:
      `/sap/opu/odata4/enercon/qm009_sb_strukrun/srvd/enercon/qm009_sd_strukrun/0001/`
- [ ] `$metadata` aufrufen → `EntitySet`s `Lot`, `StrukLog`, `WerkVH`,
      `PruefartVH`, `MaterialVH`, Aktion `aufbauen` vorhanden
- [ ] `Lot?$top=5` liefert Lose mit `MaterialText`
- [ ] SE37: `/ENERCON/QM009_STRUK_RUN` mit Los 940005101311 und `IV_TEST = X`
      → `EV_RUN_ID` gefüllt, Zeilen in `/ENERCON/QM009_L`

## Phase 4 · Frontend

Im Kunden-VS-Code:

- [ ] `git pull`, dann in `ui5_struk_run/`: `npm install`
- [ ] `ui5.yaml.example` → `ui5.yaml`, Host und Mandant des Kundensystems eintragen
- [ ] In `webapp/manifest.json` unter `sap.app.dataSources.mainService.uri`
      die Service-URL aus Phase 3 eintragen. **Einzige Codeänderung** — der
      Aktions-Namensraum wird zur Laufzeit aus den Metadaten gelesen.
      Diese Änderung nicht zurück ins Repository committen.
- [ ] `npm start` → Los suchen, **Simulieren**, Protokoll erscheint
- [ ] `ui5-deploy.yaml.example` → `ui5-deploy.yaml`: Host, Mandant, Paket,
      Transport, BSP-Name (höchstens 15 Zeichen; so benennen wie App 1 beim Kunden)
- [ ] `npm run deploy-test`, dann `npm run deploy`
- [ ] App direkt aufrufen: `/sap/bc/ui5_ui5/sap/<bsp-name>/index.html`

## Phase 5 · Launchpad

Ablauf wie in [`../ui5_equi_struk/LAUNCHPAD.md`](../ui5_equi_struk/LAUNCHPAD.md),
mit diesen Werten:

| | |
|---|---|
| Semantisches Objekt | `ZEquiStruktur` (existiert schon, wenn App 1 eingerichtet ist) |
| Aktion | `build` |
| Anwendungstyp | `SAPUI5 Fiori App` |
| URL | `/sap/bc/ui5_ui5/sap/<bsp-name>` |
| ID der SAPUI5-Komponente | `de.enercon.qm009.strukrun` |
| Kachel: Titel / Untertitel | `Equi-Struktur aufbauen` / `Equipments zum Prüflos anlegen und einbauen` |
| Kachel: Symbol | `sap-icon://process` |

- [ ] Ziel-Mapping und Kachel — in den Katalog von App 1 oder einen eigenen
- [ ] Kachel in die Gruppe (bzw. Space/Page)

## Phase 6 · Rolle

In PFCG, Rolle von App 1 erweitern oder eigene:

- [ ] **Menü:** Katalog und Gruppe aus Phase 5
- [ ] **Service:** *Autorisierungsvorschlag → SAP Gateway OData V4 Service
      Group* `/ENERCON/QM009_SB_STRUKRUN` (sonst 403 beim ersten Aufruf)
- [ ] **`S_RFC`:** `RFC_TYPE = FUGR`, `RFC_NAME = /ENERCON/QM009_STRUK`,
      `ACTVT = 16` — die Aktion ruft den Baustein per `DESTINATION 'NONE'`,
      das prüft `S_RFC` auch im selben System
- [ ] **Fachliche Berechtigungen des Echtlaufs:** Serialnummern und Equipments
      anlegen, Equipment einbauen. Welche Objekte genau greifen, zeigt der erste
      Echtlauf mit dem Testbenutzer — bei Fehler sofort `SU53`.
- [ ] Profil generieren, Testbenutzer zuordnen

## Phase 7 · Verifikation

Die sieben Punkte aus [PLAN.md](PLAN.md) („Verifikation am Ende"), mit Los
940005101311, über die Kachel gestartet.
