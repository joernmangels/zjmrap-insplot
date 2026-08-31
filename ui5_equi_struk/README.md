# Equi-Struktur-Vorgabe zum Prüfplan

Freestyle-SAPUI5-Pflegetool für die Tabelle `ZJMQM_QM009_Q`.
Backend: SAP S/4HANA (ABAP Platform 8.16), Paket `ZJMRAP_INSPLOT`.

## Fachliches Modell

Die Tabelle speichert pro Prüfplan (`PLNTY`/`PLNNR`/`PLNAL`/`ZAEHL`) und laufender
Nummer (`LFDNR`) **genau eine** Materialnummer — abgelegt in einem von zwanzig
Ebenenfeldern `MAT_EBENE0` … `MAT_EBENE19`.

Damit ist die Tabelle faktisch eine **eingerückte Strukturliste**:

| Träger | Bedeutung |
|---|---|
| `LFDNR` | Reihenfolge der Zeilen |
| Index des gefüllten Ebenenfelds | Einrückungstiefe |

Die App zeigt deshalb **keine zwanzig Spalten**, sondern eine Materialspalte mit
Einrückung. Das Verschieben zwischen Ebenen ist damit kein Zusatzfeature,
sondern die Grundbedienung: `←` rückt aus, `→` rückt ein.

## Architektur

```
ZJMQM_QM009_Q  (Tabelle, Bestand)
       │
ZJMQMS_I_EQUISTRUK  (Interface View)
       │   berechnet aus den 20 Ebenenfeldern:
       │     Ebene    = Index des gefüllten Felds (99 = keins)
       │     Material = Inhalt des gefüllten Felds
       │
       ├── BDEF (managed, early numbering, S_TABU_NAM)
       │      └── ZJMQMS_BP_EQUISTRUK  (Behavior Pool)
       │
ZJMQMS_C_EQUISTRUK  (Projection View)
       │   + Assoziation _MatText → ZJMQMS_I_MATERIAL_VH  (MARA + MAKT)
       │
ZJMQMS_SD_EQUISTRUK  (Service Definition)
       │
ZJMQMS_SB_EQUISTRUK  (Service Binding, OData V4, publiziert)
```

### Backend-Objekte

| Objekt | Typ | Zweck |
|---|---|---|
| `ZJMQMS_I_MATERIAL_VH` | DDLS | MARA + MAKT — Wertehilfe **und** Textquelle |
| `ZJMQMS_I_EQUISTRUK` | DDLS | Interface View, berechnet `Ebene` und `Material` |
| `ZJMQMS_I_EQUISTRUK` | BDEF | managed, `early numbering`, Validierung |
| `ZJMQMS_BP_EQUISTRUK` | CLAS | Behavior Pool (siehe unten) |
| `ZJMQMS_C_EQUISTRUK` | DDLS | Projection View + Textassoziation |
| `ZJMQMS_C_EQUISTRUK` | BDEF | Projection Behavior |
| `ZJMQMS_SD_EQUISTRUK` | SRVD | exponiert `EquiStruk` und `MaterialVH` |
| `ZJMQMS_SB_EQUISTRUK` | SRVB | OData V4, publiziert |
| `ZJMQMS_MC_EQUISTRUK` | DDLX | Metadata Extension — **manuell anzulegen**, Quelle in `abap/` |

### Metadata Extension anlegen

`ZJMQMS_MC_EQUISTRUK` ist das einzige Objekt, das nicht über die ADT-Schreib-API
erzeugt werden kann. In Eclipse/ADT:

1. Rechtsklick auf Paket `ZJMRAP_INSPLOT` → New → Other ABAP Repository Object
   → Core Data Services → **Metadata Extension**
2. Name `ZJMQMS_MC_EQUISTRUK`, Extended Entity `ZJMQMS_C_EQUISTRUK`,
   Transportauftrag eintragen
3. Inhalt aus [`abap/ZJMQMS_MC_EQUISTRUK.asddlxs`](abap/ZJMQMS_MC_EQUISTRUK.asddlxs)
   einfügen und aktivieren

Sie steuert die **ADT-Service-Vorschau und jede Fiori-Elements-Nutzung**:
Selektionsfelder (Plantyp, Plangruppe, Gruppenzähler, Zähler), Listenspalten
(Lfd. Nr., Ebene, Material) und blendet die 20 `MatEbeneNN`-Felder aus.
Auf die freestyle-App hat sie **keine** Wirkung — die bestimmt ihre Spalten
selbst in `Main.view.xml`.

### Warum der Materialtext nicht in der Fiori-Elements-Liste steht

`@ObjectModel.text.association` verlangt als Ziel eine echte Textsicht mit
`@ObjectModel.dataCategory: #TEXT` und einem `@Semantics.language`-Feld.
`ZJMQMS_I_MATERIAL_VH` ist das nicht — sie filtert MAKT intern auf die
Anmeldesprache und exponiert kein Sprachfeld. Setzt man die Annotation
trotzdem, aktiviert die CDS-Sicht anstandslos, aber die Service-Metadaten
lassen sich nicht mehr kompilieren (`Fehler beim Kompilieren von
'$SRVD#ZJMQMS_SD_EQUISTRUK'`, HTTP 500).

Die **freestyle-App braucht das nicht**: sie holt den Kurztext über die
Assoziation `_MatText` per `$expand` und bindet ihn als
`{_MatText/MaterialName}`. Soll der Text auch in Fiori Elements erscheinen,
wäre eine separate Textsicht auf MAKT nötig (Kardinalität `[0..*]` mit
Sprachfeld) — zusätzlich zur bestehenden `_MatText`-Assoziation, die die App
mit `[0..1]` benötigt.

### Fallstrick: Ebenenfelder dynamisch ansprechen

Der Behavior Pool spricht die 20 Ebenenfelder über `ASSIGN COMPONENT` an und
baut den Namen mit einem String-Template. Dabei ist `ALIGN = RIGHT`
**zwingend**:

```abap
" FALSCH - fuellt rechts auf: aus 1 wird MATEBENE10 statt MATEBENE01
|MATEBENE{ sy-index - 1 WIDTH = 2 PAD = '0' }|

" RICHTIG
|MATEBENE{ sy-index - 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
```

Die Standardausrichtung ist LEFT, `PAD` füllt also hinten auf. Erzeugt werden
für die Indizes 0–9 dann `MATEBENE00, MATEBENE10, MATEBENE20 … MATEBENE90`.
Die meisten davon existieren nicht — `ASSIGN COMPONENT` liefert `sy-subrc = 4` —
und `MATEBENE10` trifft ausgerechnet das falsche Feld.

Die Folge war heimtückisch: `validaterow` sah **immer** null gefüllte Ebenen und
wies jedes Speichern mit „Genau eine Materialnummer je Zeile erfassen" ab,
`current_level` meldete „Zeile enthaelt keine Materialnummer". Beides sah nach
einem Client-Problem aus, war aber reines ABAP. Aktivierung und Syntaxprüfung
melden nichts, weil der Name erst zur Laufzeit entsteht.

Festgehalten in den ABAP-Unit-Tests von `ZJMQMS_CL_PROBE` (Paket `$TMP`, nicht
im Transport — kann gelöscht oder ins Paket übernommen werden).

### Meldungstexte: maximal 50 Zeichen

`new_message_with_text( text = … )` schneidet bei 50 Zeichen ab, ohne Hinweis.
Längere Texte erscheinen im UI verstümmelt. Wer mehr braucht, legt eine
Nachrichtenklasse (MSAG) an.

### Was der Behavior Pool leistet

- **`earlynumbering_create`** — vergibt `LFDNR` als `MAX + 1` je Prüfplan.
  Mehrere Zeilen in einem Request werden korrekt durchnummeriert; eine vom
  Client mitgegebene Nummer bleibt unangetastet.
- **`normalizematerial`** — konvertiert Eingaben per `CONVERSION_EXIT_MATN1_INPUT`
  ins interne Format. Nötig, weil im System sowohl numerische
  (`000000002000000202`) als auch alphanumerische (`H1100000540`)
  Materialnummern vorkommen.
- **`validaterow`** — erzwingt „genau ein Ebenenfeld gefüllt". Ein Material ohne
  MARA-Satz wird nur als **Warnung** gemeldet, nicht blockiert (siehe Bestandsdaten).
- **`check_hierarchy`** — prüft die Ebenenfolge, siehe unten.

### Plausibilitätsprüfung der Ebenenfolge

Eine Zeile darf gegenüber ihrer **Vorgängerzeile** (nach `LFDNR`) höchstens
**eine** Ebene tiefer liegen — sonst fehlt ihr das übergeordnete Material.
Rücksprünge nach oben und Geschwister auf gleicher Ebene sind erlaubt; die
erste Zeile eines Plans muss auf Ebene 0 liegen.

Zusätzlich darf ein Plan **nur eine Wurzel** haben, also genau eine Zeile auf
Ebene 0.

```
0, 1, 2, 3, 4, 4, 3, 3, 3, 3, 2   gültig
0, 1, 5                           ungültig: Sprung von 1 auf 5
1, 2                              ungültig: erste Zeile nicht auf Ebene 0
0, 1, 2, 0, 1                     ungültig: zweite Zeile auf Ebene 0
```

Die zweite Wurzel braucht eine **eigene Zählung** — der Sprungregel fällt sie
nicht auf, weil ein Rücksprung nach oben ausdrücklich erlaubt ist.

Zwei Entscheidungen dahinter:

- **Geprüft wird der ganze Plan**, nicht nur die geänderten Zeilen. Eine
  Verschiebung kann auch die *nachfolgende* Zeile ungültig machen — die stünde
  sonst nie in `keys`. `check_hierarchy` liest dazu alle Zeilen des Plans aus
  der Datenbank, ergänzt die in dieser Transaktion neu angelegten und holt den
  aktuellen Stand per `READ ENTITIES … IN LOCAL MODE` (also inklusive der noch
  nicht gesicherten Änderungen; gelöschte Zeilen kommen nicht zurück).
- **Nur Warnung, kein Fehler.** Beim Umbauen einer Struktur entstehen
  zwangsläufig Zwischenstände, die noch nicht stimmig sind. Als harter Fehler
  würde die Prüfung jede einzelne Verschiebung blockieren.

Damit die Warnung nicht untergeht, hängt `Component.js` das Message-Modell
(`sap/ui/core/Messaging`) an. Die Tabellen-Toolbar zeigt einen Meldungsknopf
mit Anzahl, der eine `MessagePopover` öffnet; nach einer Verschiebung mit
Meldung weist der Toast darauf hin.

### Fallstrick: Warnungen brauchen Transition-Messages

Warnungen **ohne** `%state_area` melden — sonst kommen sie nie beim Client an:

```abap
" FALSCH bei Aktionen ohne Rueckgabewert
APPEND VALUE #( %tky = … %state_area = 'X' %msg = … ) TO reported-equistruk.

" RICHTIG
APPEND VALUE #( %tky = … %msg = … ) TO reported-equistruk.
```

`%state_area` erzeugt eine **State-Message**. Die hängt an der Entität und wird
nur zusammen mit deren Payload übertragen. Die Aktionen `einruecken`,
`ausruecken` und `setEbene` sind aber ohne Rückgabewert deklariert und
antworten mit `204 No Content` — es gibt keinen Payload, die Meldung fällt
still unter den Tisch. Ohne `%state_area` entsteht eine **Transition-Message**,
die im `sap-messages`-Header der Antwort mitkommt.

Fehler waren davon nicht betroffen: die schlagen fehl, und RAP liefert
Fehlermeldungen im Fehler-Body mit.

Nachgewiesen per EML im Entwicklungssystem — `COMMIT ENTITIES RESPONSE OF` lieferte
beide Warnungen (`Ebene 6 folgt auf Ebene 4`, `Material … nicht im Stamm`),
während im Browser nichts ankam.

### Fallstrick: ALPHA = OUT füllt auf 40 Zeichen auf

```abap
" schneidet die Meldung bei 50 Zeichen ab
|Material { material ALPHA = OUT } nicht im Stamm|
```

`ALPHA = OUT` liefert das komplette 40-stellige Feld inklusive Leerzeichen.
Zusammen mit dem Resttext reißt das die 50-Zeichen-Grenze von
`new_message_with_text`. Deshalb vorher in eine Variable schreiben und
`CONDENSE`.

### Meldungen nennen die Zeile zuerst

Jede Meldung beginnt mit `Zeile <n>:` — die laufende Nummer ohne führende
Nullen (`CONV i( … )`). Sie steht **am Anfang**, damit sie die
50-Zeichen-Kappung überlebt; abgeschnitten wird dann der erklärende Teil, nicht
der Bezug zur Zeile.

```
Zeile 12: Ebene 2 folgt auf 0
Zeile 12: zweite Zeile auf Ebene 0
Zeile 12: Material 2000000202 fehlt
```

Ohne den Bezug ist eine Warnung in der Meldungsliste nicht zuzuordnen — dort
steht nur der Text, nicht die Zeile, auf die sie sich bezieht.
- **`get_global_authorizations`** — prüft `S_TABU_NAM` auf `ZJMQM_QM009_Q`
  mit Aktivität 02, also dieselbe Berechtigung wie die SM30-Pflege.

## Service Binding

`ZJMQMS_SB_EQUISTRUK` ist angelegt, vom Typ **OData V4** und **publiziert**.
Alle Backend-Objekte sind aktiv, in Paket `ZJMRAP_INSPLOT` und auf dem Transportauftrag.

Angenommene Service-URL (in `webapp/manifest.json` hinterlegt):

```
/sap/opu/odata4/sap/zjmqms_sb_equistruk/srvd/sap/zjmqms_sd_equistruk/0001/
```

Per HTTP verifiziert: `$metadata` liefert HTTP 200 mit allen 20 Ebenenfeldern
und beiden Aktionen. Das `srvd` im Pfad (statt `srvd_a2x`) weist es als
**UI-Binding** aus — richtig so für eine SAPUI5-Oberfläche. Ein Web-API-Binding
wäre nur für System-zu-System-Integration nötig und könnte parallel auf
derselben Service Definition liegen.

## Frontend

```
webapp/
  Component.js
  manifest.json                        OData-V4-Modell, autoExpandSelect
  index.html
  controller/Main.controller.js         Selektion, Verschieben, Anlegen, Löschen
  view/Main.view.xml                    DynamicPage: Filter oben, Tabelle unten
  view/AddRow.fragment.xml              Dialog „Zeile anlegen"
  view/MaterialValueHelp.fragment.xml   SelectDialog gegen /MaterialVH
  model/formatter.js                    Einrückung, MATNR-Ausgabeformat
  i18n/i18n.properties                  deutsch, Umlaute als \uXXXX
  css/style.css
```

### Wie das Verschieben funktioniert

`Ebene` und `Material` sind in CDS berechnet und damit read-only. Das Umhängen
erledigt eine **RAP-Aktion** im Backend:

```js
oContext.getModel()
        .bindContext("…v0001.einruecken(...)", oContext)
        .execute()
        .then(() => oContext.requestSideEffects(["Ebene", "Material"]));
```

`move_level` im Behavior Pool leert alle Ebenenfelder und setzt die Zielebene in
einem `MODIFY ENTITIES`. Ein Zwischenstand mit null oder zwei Materialnummern
kann konstruktiv nicht entstehen.

Vorher hat das der Client mit zwei `setProperty`-Aufrufen versucht. Das ist
**nicht** zuverlässig: die beiden Änderungen landen nicht garantiert in einem
PATCH, und ein allein ankommendes Leeren lässt die RAP-Prüfung die Zeile
ablehnen. Als Aktion ist der Vorgang unteilbar, unabhängig vom Client.

`requestSideEffects` danach ist nötig, weil die berechneten CDS-Felder im
RAP-Puffer vor dem Commit noch den alten Wert tragen.

### Einrückung und Baum-Konnektor

Jede Zeile besteht aus drei Teilen: einem reinen Abstandshalter
(`formatter.indent`, **2rem je Ebene** — Ebene 19 landet damit bei 38rem), dem
Konnektor und der Materialnummer.

Der Konnektor `└▶` ist reines CSS auf einer leeren `VBox` — `border-left` und
`border-bottom` bilden den Winkel, ein `::after`-Dreieck die Pfeilspitze. Alle
Linien lassen die Farbe weg und erben damit `currentColor`, sodass die
Ebenenfarbe unten mit einer einzigen `color`-Regel greift. Für Ebene 0 ist er
ausgeblendet.

### Farbe je Ebene

Materialnummern derselben Ebene tragen dieselbe Farbe; die Einrückungslinie
bekommt sie ebenfalls. Zwei Punkte, die dabei zu beachten waren:

**`class` ist in XML-Views nicht bindbar.** Die Ebene landet deshalb per
`CustomData` mit `writeToDom="true"` als `data-ebene` im DOM, das CSS greift
über einen Attributselektor:

```xml
<core:CustomData key="ebene" value="{path: 'Ebene', formatter: '.formatter.levelText'}"
                 writeToDom="true"/>
```

**Das Horizon-Theme liefert in UI5 1.120 keine CSS-Variablen** — geprüft:
`sap/ui/core/themes/sap_horizon/library.css` enthält null `--sap*`-Definitionen,
Theme-Parameter werden zu festen Werten kompiliert. Ein reines
`var(--sapChart_OrderedColor_1)` bliebe also wirkungslos. Die Hex-Werte stammen
aus `library-parameters.json` desselben Themes und stehen als Fallback hinter
der Variablen:

```css
color: var(--sapChart_OrderedColor_1, #0070f2);
```

So wirkt heute der Hex-Wert; sollte ein künftiges Theme CSS-Variablen liefern,
übernimmt es automatisch. Es gibt 11 Chart-Farben für 20 Ebenen — ab Ebene 11
wiederholen sie sich, die Einrückung unterscheidet die Zeilen dann weiterhin.

### Zeile vertikal verschieben

Zwei Pfeile pro Zeile plus Direkteingabe der laufenden Nummer — dieselbe
Bedienlogik wie bei der Ebene, umgesetzt über die Aktionen `nachOben`,
`nachUnten` und `setPosition`.

**`LFDNR` bleibt dabei unangetastet.** Als Schlüsselfeld lässt es sich in RAP
nicht ändern, und Umnummerieren hieße löschen und neu anlegen. Stattdessen
wandert der **Inhalt**: die Materialnummern rotieren über den betroffenen
Bereich, die laufenden Nummern bleiben stehen. Optisch identisch, ohne
Schlüsseleingriff — und `LFDNR` behält seine einzige Aufgabe, die Reihenfolge
zu tragen.

```
vorher:  1:A  2:B  3:C  4:D        Zeile 4 auf Position 2
nachher: 1:A  2:D  3:B  4:C
```

Geschrieben wird nur der rotierte Bereich, nicht der ganze Plan.

Nach jeder Aktion liest die App die **komplette Liste** neu statt gezielter
SideEffects: beim vertikalen Verschieben ändern sich mehrere Zeilen, einzelne
`requestSideEffects` würden die Nachbarn veraltet stehen lassen.

### Ebene direkt eingeben

Neben den Pfeiltasten trägt jede Zeile ein Eingabefeld für die Ebene. Es ruft
die Aktion `setEbene` mit dem absoluten Zielwert auf:

```js
oOperation.setParameter("Ebene", iTarget);
```

Backend-seitig ist das dieselbe Routine: `move_level` nimmt wahlweise eine
Schrittweite (`iv_delta`) **oder** eine absolute Zielebene (`iv_target`). Die
Zielebene kommt je Zeile aus `%param`, mehrere Zeilen können also
unterschiedliche Werte bekommen.

Das Feld ist **OneWay** gebunden — `Ebene` ist im BO read-only, eine
TwoWay-Bindung würde einen PATCH darauf versuchen. Der UI5-Language-Server
markiert `mode: 'OneWay'` fälschlich als Fehler; `'OneWay'` ist der korrekte
Enum-Wert von `sap.ui.model.BindingMode`, die qualifizierte Schreibweise wäre
zur Laufzeit ein ungültiger String.

Eingaben außerhalb 0–19 oder Nicht-Zahlen fängt der Controller ab und setzt das
Feld auf den tatsächlichen Stand zurück; die Bereichsprüfung läuft zusätzlich
im Backend.

## App starten

```bash
cp ui5.yaml.example ui5.yaml          # einmalig, dann Host und Mandant eintragen
npm install                           # einmalig
npm start                             # oeffnet http://localhost:8080/index.html
```

`ui5.yaml` und `ui5-deploy.yaml` liegen **nicht** im Repository — sie enthalten
Hostname, Mandant und Transportauftrag des konkreten Systems. Im Repository
stehen nur die Vorlagen `ui5.yaml.example` und `ui5-deploy.yaml.example`.

`fiori-tools-proxy` leitet `/sap/...` an das dort eingetragene ABAP-System
weiter und lädt UI5 1.120 von `ui5.sap.com`. Beim ersten Backend-Request fragt
der Browser nach den SAP-Zugangsdaten.

Server ohne Browser starten: `npx ui5 serve --port 8080`. Beenden mit `Ctrl+C`.

Service direkt prüfen (Server muss laufen):

```bash
curl 'http://localhost:8080/sap/opu/odata4/sap/zjmqms_sb_equistruk/srvd/sap/zjmqms_sd_equistruk/0001/$metadata'
```

### Konvertierungsroutinen macht der Gateway

Der OData-Service liefert und akzeptiert **externes** Format: `PlanGroup` kommt
als `4` zurück, nicht `00000004`, `Material` als `1074348`. Filterwerte werden
ebenso konvertiert — `PlanGroup eq '4'` findet die Zeilen zu `00000004`.
Die App füllt deshalb **nicht** selbst mit Nullen auf, sie trimmt nur und
schreibt gross. Die ABAP-Determination `normalizematerial` bleibt als Netz
für Sonderfälle bestehen.

## Deployment ins ABAP-System

```bash
cp ui5-deploy.yaml.example ui5-deploy.yaml   # einmalig, dann ausfuellen
npm run deploy-test                          # Trockenlauf
npm run deploy                               # BSP ZJMQMS_EQUISTR
```

Das Deployment bringt **nur das Frontend**. Die ABAP-Objekte müssen im
Zielsystem vorher vorhanden sein — per Transport oder abapGit-Pull aus diesem
Repository.

### UI5 wird absolut geladen

`webapp/index.html` bootstrappt UI5 über

```
/sap/public/bc/ui5_ui5/resources/sap-ui-core.js
```

und **nicht** relativ über `resources/sap-ui-core.js`. Der relative Pfad
funktioniert nur lokal: als BSP unter `/sap/bc/ui5_ui5/sap/<name>/` würde daraus
`/sap/bc/ui5_ui5/sap/<name>/resources/…` und damit ein 404 — die deployte App
ließe sich nicht direkt aufrufen.

Der absolute Pfad wird lokal ebenfalls über den `/sap`-Proxy bedient und liefert
immer die UI5-Version des jeweiligen Systems. Im Entwicklungssystem sind das
1.136.21; alle von der App genutzten Module (`sap/ui/core/Messaging`,
`sap/m/MessagePopover`, `sap/f/DynamicPage`, `sap/ui/core/CustomData`) sind dort
vorhanden.

Beim Aufruf über die Fiori-Launchpad spielt `index.html` ohnehin keine Rolle —
dort lädt die Shell direkt `Component.js`.

## Bekannte Randbedingungen

- **Zwanzig Ebenen.** Die Tabelle hat `MAT_EBENE0` bis `MAT_EBENE19`.
  Die App bietet entsprechend die Ebenen 0–19 an.
- **Verwaiste Bestandsdaten.** Die vorhandenen Zeilen zu Plan `Q/00000004/02`
  verweisen auf Materialien (`…1074348`, `…1076780`, …), die in MARA/MAKT
  dieses Systems nicht existieren. Sie werden ohne Kurztext angezeigt; beim
  Speichern erscheint eine Warnung. Das ist kein Fehler der Anwendung.
- **Reihenfolge ändern ist nicht enthalten.** `LFDNR` ist Schlüsselfeld;
  Umsortieren hieße Schlüssel neu vergeben. Bewusst ausgeklammert.
- **Die Wertehilfe heißt `MaterialVH`, nicht `Material`.** RAP leitet aus
  `expose … as X` den EDM-Entitytyp `XType` ab. Bei `as Material` entstünde
  `MaterialType` — und damit ein Konflikt mit der gleichnamigen Eigenschaft
  (MARA-MTART). Die Metadaten ließen sich dann nicht erzeugen, der Service
  antwortete mit HTTP 500. Die CDS-Aktivierung meldet das nicht, der Fehler
  tritt erst bei der EDM-Generierung zur Laufzeit auf.
