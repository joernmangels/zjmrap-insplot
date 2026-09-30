sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/ui/core/format/DateFormat",
    "sap/m/SelectDialog",
    "sap/m/StandardListItem",
    "sap/m/MessageBox",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Sorter",
    "sap/ui/comp/smartvariants/PersonalizableInfo",
    "sap/m/DynamicDateRange"
], (Controller, Filter, FilterOperator, DateFormat, SelectDialog, StandardListItem, MessageBox, JSONModel,
    Sorter, PersonalizableInfo, DynamicDateRange) => {
    "use strict";

    // Edm.Date erwartet im Filter einen String "yyyy-MM-dd", kein Date-Objekt
    const oEdmDate = DateFormat.getDateInstance({ pattern: "yyyy-MM-dd" });

    // Textfelder der Filterleiste und die Eigenschaft im Service, auf die sie filtern
    const TEXT_FILTERS = {
        prueflosInput: "Prueflos",
        werkInput: "Werk",
        pruefartInput: "Pruefart",
        materialInput: "Material",
        chargeInput: "Charge",
        herkunftInput: "Herkunft"
    };

    // Sortierung ohne Variante: neueste Lose zuerst
    const DEFAULT_SORT = { path: "Prueflos", descending: true };

    // Je Filterfeld: woraus die Wertehilfe liest und welche Eigenschaft
    // uebernommen wird. Gesucht wird per $search (@Search im Backend).
    const VALUE_HELP = {
        prueflosInput: { title: "vhPrueflos", path: "/Lot", key: "Prueflos", text: "MaterialText" },
        werkInput: { title: "vhWerk", path: "/WerkVH", key: "Werk", text: "WerkName" },
        pruefartInput: { title: "vhPruefart", path: "/PruefartVH", key: "Pruefart", text: "PruefartText" },
        // $search findet die Materialnummer nicht (intern mit fuehrenden
        // Nullen), daher Zahlen per $filter - dort ergaenzt das Gateway sie
        materialInput: { title: "vhMaterial", path: "/MaterialVH", key: "Material", text: "MaterialName",
            numberAsFilter: true }
    };

    return Controller.extend("de.enercon.qm009.strukrun.controller.LotList", {
        onInit() {
            this._mValueHelpDialogs = {};
            this.getView().setModel(new JSONModel({
                selectedCount: 0,
                lotCount: 0,
                sort: Object.assign({}, DEFAULT_SORT)
            }), "view");
            this._initVariantManagement();
        },

        /* ============================================================
         * Varianten
         *
         * Die FilterBar kennt den Inhalt ihrer Felder nicht selbst (keine
         * SmartFilterBar). Deshalb liefert der Controller ihr drei Funktionen:
         * was gespeichert wird (fetchData), wie es zurueckkommt (applyData)
         * und welche Felder gefuellt sind (fuer den Zaehler "Filter (n)").
         * Gespeichert wird das JSON im Flex-Dienst, je Benutzer.
         * ============================================================ */

        _initVariantManagement() {
            const oFilterBar = this.byId("filterBar");
            const oVariantManagement = this.byId("variantManagement");

            oFilterBar.registerFetchData(() => this._fetchVariantData());
            oFilterBar.registerApplyData((oData) => this._applyVariantData(oData));
            oFilterBar.registerGetFiltersWithValues(() => this._getFiltersWithValues());

            oVariantManagement.addPersonalizableControl(new PersonalizableInfo({
                type: "filterBar",
                keyName: "persistencyKey",
                dataSource: "",
                control: oFilterBar
            }));
            // Laedt die Varianten und wendet die Standardvariante an; erst
            // danach die Liste lesen (Binding ist bis dahin angehalten)
            oVariantManagement.initialise(() => this.onSearch(), oFilterBar);
        },

        /** Zustand fuer die Variante: gefuellte Filter und die Sortierung */
        _fetchVariantData() {
            const mFilters = {};
            Object.keys(TEXT_FILTERS).forEach((sInputId) => {
                const sValue = this.byId(sInputId).getValue().trim();
                if (sValue) {
                    mFilters[sInputId] = sValue;
                }
            });

            // Gespeichert wird die Regel ({operator: "LASTDAYS", values: [30]}),
            // nicht das Datum - so bleibt "letzte 30 Tage" auch morgen richtig
            const oDateValue = this.byId("datumRange").getValue();
            if (oDateValue) {
                mFilters.datum = {
                    operator: oDateValue.operator,
                    // Feste Daten (DATE, DATERANGE, FROM, TO) als Text, JSON kennt kein Date
                    values: oDateValue.values.map((vValue) =>
                        vValue instanceof Date ? { date: oEdmDate.format(vValue) } : vValue)
                };
            }

            return { filters: mFilters, sort: this._getSort() };
        },

        _applyVariantData(oData) {
            const mFilters = (oData && oData.filters) || {};
            Object.keys(TEXT_FILTERS).forEach((sInputId) => {
                this.byId(sInputId).setValue(mFilters[sInputId] || "");
            });

            const oDatum = mFilters.datum;
            this.byId("datumRange").setValue(oDatum ? {
                operator: oDatum.operator,
                values: oDatum.values.map((vValue) =>
                    vValue && vValue.date ? oEdmDate.parse(vValue.date) : vValue)
            } : undefined);

            this.getView().getModel("view").setProperty("/sort",
                Object.assign({}, (oData && oData.sort) || DEFAULT_SORT));
        },

        _getFiltersWithValues() {
            return this.byId("filterBar").getFilterGroupItems().filter((oItem) => {
                const oControl = oItem.getControl();
                return oControl.isA("sap.m.DynamicDateRange")
                    ? Boolean(oControl.getValue())
                    : Boolean(oControl.getValue().trim());
            });
        },

        /** Unvollstaendige Eingaben ("Letzte _ Tage" ohne Zahl) nicht als Aenderung werten */
        onDateChange(oEvent) {
            if (oEvent.getParameter("valid")) {
                this.onFilterFieldChange();
            }
        },

        /** Beim Wechsel der Variante gleich suchen - die Liste soll zur Variante passen */
        onAfterVariantLoad() {
            this.onSearch();
        },

        /** Eine Aenderung macht die aktuelle Variante "geaendert" (Stern am Namen) */
        onFilterFieldChange() {
            this._markVariantModified();
            this.byId("filterBar").fireFilterChange();
        },

        _markVariantModified() {
            this.byId("variantManagement").currentVariantSetModified(true);
        },

        /* ============================================================
         * Sortierung - laeuft im Backend ($orderby), damit sie auch fuer
         * noch nicht nachgeladene Zeilen stimmt
         * ============================================================ */

        _getSort() {
            return Object.assign({}, this.getView().getModel("view").getProperty("/sort"));
        },

        async onOpenSortDialog() {
            this._pSortDialog ??= this.loadFragment({ name: "de.enercon.qm009.strukrun.view.SortDialog" });
            const oDialog = await this._pSortDialog;

            // Dialog auf die aktuell gueltige Sortierung einstellen (kann aus einer Variante stammen)
            const oSort = this._getSort();
            const oItem = oDialog.getSortItems().find((oSortItem) => oSortItem.getKey() === oSort.path);
            oDialog.setSelectedSortItem(oItem);
            oDialog.setSortDescending(oSort.descending);
            oDialog.open();
        },

        onSortConfirm(oEvent) {
            const oItem = oEvent.getParameter("sortItem");
            if (!oItem) {
                return;
            }
            this.getView().getModel("view").setProperty("/sort", {
                path: oItem.getKey(),
                descending: oEvent.getParameter("sortDescending")
            });
            this._markVariantModified();
            this._resetSelection();

            const oSort = this._getSort();
            this.byId("lotTable").getBinding("items").sort(new Sorter(oSort.path, oSort.descending));
        },

        /** Neue Reihenfolge oder Trefferliste: alte Markierungen passen nicht mehr */
        _resetSelection() {
            this.byId("lotTable").removeSelections(true);
            this._updateSelectedCount();
        },

        onLotTableUpdated(oEvent) {
            // Gesamtzahl der Treffer ($count), nicht nur die geladenen Zeilen
            this.getView().getModel("view").setProperty("/lotCount", oEvent.getParameter("total"));
        },

        onSelectionChange() {
            this._updateSelectedCount();
        },

        _updateSelectedCount() {
            const iCount = this.byId("lotTable").getSelectedContexts().length;
            this.getView().getModel("view").setProperty("/selectedCount", iCount);
        },

        onSimulate() {
            this._runAufbau(false);
        },

        onBuild() {
            const oLot = this.byId("lotTable").getSelectedContexts()[0];
            if (!oLot) {
                return;
            }

            // Echtlauf legt Equipments an und baut sie ein - daher Rueckfrage
            // mit der Losnummer und "Abbrechen" als Vorbelegung
            const oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
            MessageBox.confirm(oBundle.getText("buildConfirm", [oLot.getProperty("Prueflos")]), {
                title: oBundle.getText("buildConfirmTitle"),
                emphasizedAction: MessageBox.Action.CANCEL,
                onClose: (sAction) => {
                    if (sAction === MessageBox.Action.OK) {
                        this._runAufbau(true);
                    }
                }
            });
        },

        /**
         * Ruft die Aktion "aufbauen" fuer das markierte Los auf und springt
         * danach ins Protokoll. Ein Los je Lauf (PLAN.md, Schritt 10).
         * Ohne Echtlauf simuliert das Backend nur, geschrieben wird dann
         * allein das Protokoll.
         */
        async _runAufbau(bEchtlauf) {
            const oLot = this.byId("lotTable").getSelectedContexts()[0];
            if (!oLot) {
                return;
            }

            const oView = this.getView();
            oView.setBusy(true);
            try {
                // Gebundene Aktion: der Los-Kontext liefert den Schluessel (_it)
                const sNamespace = await this._getServiceNamespace(oLot.getModel());
                const oOperation = oLot.getModel().bindContext(sNamespace + "aufbauen(...)", oLot);
                oOperation.setParameter("Echtlauf", bEchtlauf);

                await oOperation.execute();
                // Ergebnis ist der Complex Type ZJMQMS_A_RUN mit der Lauf-ID
                const sRunId = oOperation.getBoundContext().getProperty("RunId");
                this.getOwnerComponent().getRouter().navTo("RouteRunLog", { RunId: sRunId });
            } catch (oError) {
                const oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
                MessageBox.error(oBundle.getText("runFailed", [oLot.getProperty("Prueflos"), oError.message]));
            } finally {
                oView.setBusy(false);
            }
        },

        /**
         * Namensraum der Aktionen aus den Metadaten statt fest im Code: er
         * haengt am Namen des Service und ist in VID (zjmqms_sd_strukrun)
         * und beim Kunden (/ENERCON/...) verschieden. $EntityContainer
         * liefert z. B. "com.sap.gateway.srvd.zjmqms_sd_strukrun.v0001.Container".
         */
        async _getServiceNamespace(oModel) {
            const sContainer = await oModel.getMetaModel().requestObject("/$EntityContainer");
            return sContainer.slice(0, sContainer.lastIndexOf(".") + 1);
        },

        /**
         * Zeitraum aus der Regel erst beim Suchen in Daten umrechnen: "Letzte
         * 30 Tage" gilt immer ab heute. "Ab"/"Bis" haben nur eine Grenze.
         */
        _getDateFilter() {
            const oDateValue = this.byId("datumRange").getValue();
            if (!oDateValue) {
                return null;
            }
            const aDates = DynamicDateRange.toDates(oDateValue).map((oDate) => oEdmDate.format(new Date(oDate.getTime())));

            switch (oDateValue.operator) {
                case "FROM":
                    return new Filter("Entstehungsdatum", FilterOperator.GE, aDates[0]);
                case "TO":
                    return new Filter("Entstehungsdatum", FilterOperator.LE, aDates[0]);
                default:
                    return new Filter("Entstehungsdatum", FilterOperator.BT, aDates[0], aDates[aDates.length - 1]);
            }
        },

        onValueHelp(oEvent) {
            const oInput = oEvent.getSource();
            const sInputId = this.getView().getLocalId(oInput.getId());
            const oDialog = this._getValueHelpDialog(sInputId, oInput);

            // Mit dem bisherigen Feldinhalt als Suchbegriff oeffnen
            const sValue = oInput.getValue().trim();
            this._searchValueHelp(oDialog, VALUE_HELP[sInputId], sValue);
            oDialog.open(sValue);
        },

        _getValueHelpDialog(sInputId, oInput) {
            if (this._mValueHelpDialogs[sInputId]) {
                return this._mValueHelpDialogs[sInputId];
            }

            const oConfig = VALUE_HELP[sInputId];
            const oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
            const oDialog = new SelectDialog({
                title: oBundle.getText(oConfig.title),
                growing: true,
                growingThreshold: 50,
                items: {
                    path: oConfig.path,
                    template: new StandardListItem({
                        title: `{${oConfig.key}}`,
                        description: `{${oConfig.text}}`
                    })
                },
                search: (oSearchEvent) => {
                    this._searchValueHelp(oDialog, oConfig, oSearchEvent.getParameter("value"));
                },
                confirm: (oConfirmEvent) => {
                    const oItem = oConfirmEvent.getParameter("selectedItem");
                    if (oItem) {
                        oInput.setValue(oItem.getTitle());
                        // setValue loest kein change aus - Variante selbst als geaendert markieren
                        this.onFilterFieldChange();
                    }
                }
            });

            // Als abhaengiges Element erbt der Dialog Modelle und Lebensdauer der View
            this.getView().addDependent(oDialog);
            this._mValueHelpDialogs[sInputId] = oDialog;
            return oDialog;
        },

        _searchValueHelp(oDialog, oConfig, sValue) {
            const oBinding = oDialog.getBinding("items");
            const sTerm = (sValue || "").trim();

            if (oConfig.numberAsFilter && /^\d+$/.test(sTerm)) {
                oBinding.changeParameters({ $search: undefined });
                oBinding.filter(new Filter(oConfig.key, FilterOperator.EQ, sTerm));
            } else {
                // Leerer Suchbegriff: $search entfernen, dann alle Treffer
                oBinding.filter([]);
                oBinding.changeParameters({ $search: sTerm || undefined });
            }
        },

        onSearch() {
            const aFilter = [];

            Object.keys(TEXT_FILTERS).forEach((sInputId) => {
                const sValue = this.byId(sInputId).getValue().trim().toUpperCase();
                if (sValue) {
                    aFilter.push(new Filter(TEXT_FILTERS[sInputId], FilterOperator.EQ, sValue));
                }
            });

            const oDateFilter = this._getDateFilter();
            if (oDateFilter) {
                aFilter.push(oDateFilter);
            }

            this._resetSelection();

            // Sortierung mitsetzen: sie kann gerade aus einer Variante gekommen sein
            const oSort = this._getSort();
            const oBinding = this.byId("lotTable").getBinding("items");
            oBinding.sort(new Sorter(oSort.path, oSort.descending));
            oBinding.filter(aFilter);
            // Beim ersten Aufruf ist das Binding noch angehalten (suspended in der View)
            if (oBinding.isSuspended()) {
                oBinding.resume();
            }
        }
    });
});
