# Anbindung an die SAP Fiori Launchpad

Das Deployment (`npm run deploy`) legt nur die BSP-Anwendung an. Damit die App
als Kachel erscheint, braucht es zusätzlich eine Konfiguration im ABAP-System.
Diese Datei beschreibt sie mit den konkreten Werten dieser App.

## Was die App bereits mitbringt

In `webapp/manifest.json` steht unter `sap.app.crossNavigation` ein Inbound:

| | |
|---|---|
| Semantisches Objekt | `ZEquiStruktur` |
| Aktion | `maintain` |
| Titel / Untertitel | aus i18n: `flpTitle`, `flpSubtitle` |
| Symbol | `sap-icon://tree` |

Damit beschreibt sich die App der Launchpad gegenüber selbst. Das ersetzt die
Konfiguration im System **nicht**, hält beide Seiten aber konsistent.

## Werte für die Konfiguration

| | |
|---|---|
| BSP-Anwendung | `ZJMQMS_EQUISTR` |
| URL | `/sap/bc/ui5_ui5/sap/zjmqms_equistr` |
| SAPUI5-Komponente | `de.enercon.qm009.equistruk` |
| Semantisches Objekt | `ZEquiStruktur` |
| Aktion | `maintain` |

Weichen BSP-Name oder Paket im Zielsystem ab, gelten die Werte aus der dortigen
`ui5-deploy.yaml`.

---

## Schritt 1 · Semantisches Objekt anlegen

Transaktion **`/UI2/SEMOBJ`** (Customizing, änderbar):

- Semantisches Objekt: `ZEquiStruktur`
- Beschreibung: `Equi-Struktur zum Pruefplan`

Ohne diesen Eintrag lässt sich im nächsten Schritt kein Ziel-Mapping anlegen.

## Schritt 2 · Katalog, Ziel-Mapping und Kachel

Transaktion **`/UI2/FLPD_CUST`** (Launchpad Designer, Customizing-Bereich).

**Katalog anlegen**

- Katalog-ID: `ZQM_EQUISTRUK`
- Titel: `QM Equi-Struktur`

**Ziel-Mapping hinzufügen**

| Feld | Wert |
|---|---|
| Semantisches Objekt | `ZEquiStruktur` |
| Aktion | `maintain` |
| Anwendungstyp | `SAPUI5 Fiori App` |
| Titel | `Equi-Struktur` |
| URL | `/sap/bc/ui5_ui5/sap/zjmqms_equistr` |
| ID der SAPUI5-Komponente | `de.enercon.qm009.equistruk` |

Bei *Geräteart* Desktop und Tablet ankreuzen, Smartphone abwählen — die App ist
für Telefone nicht ausgelegt (`sap.ui.deviceTypes.phone` steht auf `false`).

**Kachel hinzufügen**

- Typ: *Statischer App-Starter*
- Titel: `Equi-Struktur`
- Untertitel: `Vorgabe zum Prüfplan pflegen`
- Symbol: `sap-icon://tree`
- Navigation: semantisches Objekt `ZEquiStruktur`, Aktion `maintain`

## Schritt 3 · Gruppe anlegen

Im selben Designer eine Gruppe `ZQM_EQUISTRUK_GRP` anlegen und die Kachel aus
dem Katalog hineinziehen. Ohne Gruppe erscheint die Kachel nicht automatisch auf
der Startseite — sie wäre nur über die Suche auffindbar.

## Schritt 4 · Rolle zuordnen

Transaktion **`PFCG`**:

1. Rolle anlegen oder bestehende QM-Rolle öffnen
2. Reiter *Menü* → *Transaktion einfügen* → **SAP Fiori Kachelkatalog** →
   `ZQM_EQUISTRUK`
3. Ebenso die Gruppe `ZQM_EQUISTRUK_GRP` zuordnen
4. Berechtigungsprofil generieren, Benutzer zuordnen

**Fachliche Berechtigung nicht vergessen:** der RAP-BO prüft `S_TABU_NAM` auf
die Tabelle `ZJMQM_QM009_Q` mit Aktivität `02`. Ohne diese Berechtigung öffnet
sich die App, das Ändern schlägt aber fehl.

## Schritt 5 · Prüfen

1. Launchpad neu laden, Kachel erscheint in der Gruppe
2. Kachel öffnen → die App startet ohne `index.html`; die Shell lädt direkt
   `Component.js`
3. Einen Prüfplan selektieren und eine Zeile verschieben

Bleibt die Kachel leer oder wirft die App einen Komponentenfehler, zuerst
prüfen, ob die ID der SAPUI5-Komponente im Ziel-Mapping exakt
`de.enercon.qm009.equistruk` lautet — sie muss mit `sap.app.id` im Manifest
übereinstimmen.

---

## Alternative: Launchpad-App-Deskriptor

Ab S/4HANA 2020 gibt es zusätzlich die *Launchpad App Descriptor Items*
(Transaktion `/UI2/FLPAM` bzw. der Launchpad Content Manager). Damit liest das
System den Inbound direkt aus dem Manifest der deployten App, statt Ziel-Mapping
und Kachel von Hand zu pflegen.

Der oben beschriebene Weg über `/UI2/FLPD_CUST` funktioniert in jedem Release
und ist deshalb hier ausführlich beschrieben. Welcher Weg im Zielsystem der
übliche ist, entscheidet die dortige Basis-Mannschaft.

## Nicht geprüft

Diese Anleitung ist **nicht** im System durchgespielt worden — die
Launchpad-Konfiguration ist über die ADT-Schnittstelle nicht erreichbar. Die
Werte stammen aus dem Manifest und der Deploy-Konfiguration dieses Projekts,
die Abläufe aus der Standardvorgehensweise für freestyle-SAPUI5-Apps auf
ABAP on premise.
