sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/Fragment",
    "sap/ui/core/Messaging",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "sap/m/MessageBox",
    "sap/m/MessageToast",
    "de/enercon/qm009/equistruk/model/formatter"
], function (Controller, Fragment, Messaging, JSONModel, Filter, FilterOperator, MessageBox, MessageToast, formatter) {
    "use strict";

    var MAX_LEVEL = formatter.MAX_LEVEL;

    // Namensraum der gebundenen Aktionen aus $metadata des Service Bindings.
    // Er leitet sich aus dem Namen der Service Definition ab und aendert sich
    // nur, wenn ZJMQMS_SD_EQUISTRUK umbenannt wird.
    var ACTION_NS = "com.sap.gateway.srvd.zjmqms_sd_equistruk.v0001.";

    return Controller.extend("de.enercon.qm009.equistruk.controller.Main", {

        formatter: formatter,

        /* ---------------------------------------------------------------- */
        /* Lifecycle                                                        */
        /* ---------------------------------------------------------------- */

        onInit: function () {
            var aLevels = [];
            for (var i = 0; i <= MAX_LEVEL; i++) {
                aLevels.push({ key: String(i), text: String(i) });
            }

            this.getView().setModel(new JSONModel({
                planType: "Q",
                planGroup: "",
                groupCounter: "",
                nodeCounter: "",
                planDescription: "",
                planSelected: false,
                busy: false,
                levels: aLevels,
                newMaterial: "",
                newLevel: "0"
            }), "ui");
        },

        /* ---------------------------------------------------------------- */
        /* Selektion                                                        */
        /* ---------------------------------------------------------------- */

        onSearch: function () {
            var oUiModel = this.getView().getModel("ui");
            var oFilterData = oUiModel.getData();

            var sPlanType     = this._normalize(oFilterData.planType);
            var sPlanGroup    = this._normalize(oFilterData.planGroup);
            var sGroupCounter = this._normalize(oFilterData.groupCounter);
            var sNodeCounter  = this._normalize(oFilterData.nodeCounter);

            if (!sPlanType || !sPlanGroup || !sGroupCounter || !sNodeCounter) {
                MessageBox.warning(this._text("msgFilterIncomplete"));
                return;
            }

            // Normalisierte Werte zurueckschreiben, damit der Anwender sieht,
            // womit tatsaechlich selektiert wurde
            oUiModel.setProperty("/planType", sPlanType);
            oUiModel.setProperty("/planGroup", sPlanGroup);
            oUiModel.setProperty("/groupCounter", sGroupCounter);
            oUiModel.setProperty("/nodeCounter", sNodeCounter);

            var oBinding = this.byId("structureTable").getBinding("items");

            oBinding.filter([
                new Filter("PlanType", FilterOperator.EQ, sPlanType),
                new Filter("PlanGroup", FilterOperator.EQ, sPlanGroup),
                new Filter("GroupCounter", FilterOperator.EQ, sGroupCounter),
                new Filter("NodeCounter", FilterOperator.EQ, sNodeCounter)
            ]);

            if (oBinding.isSuspended()) {
                oBinding.resume();
            }

            oUiModel.setProperty("/planSelected", true);
            oUiModel.setProperty("/planDescription", this._text("planDescription", [
                sPlanType, sPlanGroup, sGroupCounter, sNodeCounter
            ]));
        },

        /**
         * Meldungsliste des Backends. Die Ebenenpruefung meldet nur Warnungen,
         * die kommen in einer erfolgreichen Antwort mit und wuerden ohne diese
         * Anzeige unbemerkt bleiben.
         */
        onShowMessages: function (oEvent) {
            var oView   = this.getView();
            var oButton = oEvent.getSource();

            if (!this._pMessages) {
                this._pMessages = Fragment.load({
                    id: oView.getId(),
                    name: "de.enercon.qm009.equistruk.view.Messages",
                    controller: this
                }).then(function (oPopover) {
                    oView.addDependent(oPopover);
                    return oPopover;
                });
            }

            this._pMessages.then(function (oPopover) {
                oPopover.openBy(oButton);
            });
        },

        onRefresh: function () {
            var oBinding = this.byId("structureTable").getBinding("items");
            if (oBinding && !oBinding.isSuspended()) {
                oBinding.refresh();
            }
        },

        /* ---------------------------------------------------------------- */
        /* Ebene verschieben - der Kern der Anwendung                        */
        /* ---------------------------------------------------------------- */

        onIndent: function (oEvent) {
            this._moveLevel(oEvent.getSource().getBindingContext(), 1);
        },

        onOutdent: function (oEvent) {
            this._moveLevel(oEvent.getSource().getBindingContext(), -1);
        },

        /**
         * Verschiebt die Materialnummer einer Zeile um eine Ebene.
         *
         * Das Umhaengen erledigt die RAP-Aktion 'einruecken' bzw. 'ausruecken'
         * im Backend: sie leert das alte Ebenenfeld und setzt das neue in einem
         * Zug. Frueher hat das der Client mit zwei setProperty-Aufrufen erledigt
         * - die landeten aber nicht zuverlaessig in einem PATCH, und ein allein
         * ankommendes Leeren liess die RAP-Pruefung die Zeile ablehnen. Als
         * Aktion ist der Vorgang unteilbar, unabhaengig vom Client.
         *
         * Ebene und Material sind in der CDS-Sicht berechnet und stehen im
         * RAP-Puffer vor dem Commit noch auf dem alten Wert, deshalb werden sie
         * danach gezielt nachgelesen.
         */
        _moveLevel: function (oContext, iDelta) {
            if (!oContext) {
                return;
            }

            var iLevel  = parseInt(oContext.getProperty("Ebene"), 10);
            var iTarget = iLevel + iDelta;

            if (isNaN(iLevel) || iTarget < 0 || iTarget > MAX_LEVEL) {
                return;
            }

            this._execAction(oContext,
                             iDelta > 0 ? "einruecken" : "ausruecken",
                             null,
                             "msgMoved",
                             [iTarget]);
        },

        /* ---------------------------------------------------------------- */
        /* Zeile vertikal verschieben                                        */
        /* ---------------------------------------------------------------- */

        onMoveUp: function (oEvent) {
            this._execAction(oEvent.getSource().getBindingContext(),
                             "nachOben", null, "msgReordered");
        },

        onMoveDown: function (oEvent) {
            this._execAction(oEvent.getSource().getBindingContext(),
                             "nachUnten", null, "msgReordered");
        },

        /**
         * Direkteingabe der laufenden Nummer. Wie bei der Ebene ist das Feld
         * nur lesend gebunden; die Aktion setPosition erledigt das Umhaengen.
         */
        onSeqChange: function (oEvent) {
            var oInput   = oEvent.getSource();
            var oContext = oInput.getBindingContext();

            if (!oContext) {
                return;
            }

            var sValue   = String(oEvent.getParameter("value") || "").trim();
            var iCurrent = parseInt(oContext.getProperty("SeqNumber"), 10);

            if (!/^\d{1,6}$/.test(sValue) || parseInt(sValue, 10) < 1) {
                MessageBox.warning(this._text("msgSeqInvalid"));
                oInput.setValue(iCurrent);
                return;
            }

            var iTarget = parseInt(sValue, 10);

            if (iTarget === iCurrent) {
                oInput.setValue(iCurrent);
                return;
            }

            this._execAction(oContext, "setPosition",
                             { TargetSeqNumber: iTarget },
                             "msgReordered");
        },

        /* ---------------------------------------------------------------- */
        /* Gemeinsamer Aktionsaufruf                                         */
        /* ---------------------------------------------------------------- */

        /**
         * Ruft eine gebundene RAP-Aktion auf und liest die Liste danach neu.
         *
         * Neu gelesen wird immer die ganze Liste, nicht nur die betroffene
         * Zeile: beim vertikalen Verschieben rotiert der Inhalt ueber mehrere
         * Zeilen, gezielte SideEffects wuerden die Nachbarn veraltet stehen
         * lassen. Bei einem Fehler wird ebenfalls neu gelesen, damit die
         * Eingabefelder wieder den tatsaechlichen Stand zeigen.
         */
        _execAction: function (oContext, sAction, oParameters, sToastKey, aToastArgs) {
            if (!oContext) {
                return;
            }

            var that       = this;
            var oOperation = oContext.getModel()
                                     .bindContext(ACTION_NS + sAction + "(...)", oContext);

            if (oParameters) {
                Object.keys(oParameters).forEach(function (sName) {
                    oOperation.setParameter(sName, oParameters[sName]);
                });
            }

            Messaging.removeAllMessages();
            this._setBusy(true);

            oOperation.execute().then(function () {
                that._refreshTable();
                that._setBusy(false);
                that._notify(sToastKey, aToastArgs);
            }).catch(function (oError) {
                that._refreshTable();
                that._setBusy(false);
                that._showError(oError);
            });
        },

        _refreshTable: function () {
            var oBinding = this.byId("structureTable").getBinding("items");
            if (oBinding && !oBinding.isSuspended()) {
                oBinding.refresh();
            }
        },

        /**
         * Erfolgsmeldung. Die Plausibilitaetspruefungen melden nur Warnungen -
         * die kommen mit einer erfolgreichen Antwort und wuerden sonst nur im
         * Meldungsknopf auftauchen, ohne dass jemand hinsieht.
         */
        _notify: function (sToastKey, aArgs) {
            var bHasMessages = (Messaging.getMessageModel().getData() || []).length > 0;
            MessageToast.show(
                bHasMessages ? this._text("msgCheckMessages")
                             : this._text(sToastKey, aArgs)
            );
        },

        /**
         * Direkteingabe der Ebene in der Tabellenzeile. Die Eingabe ist
         * OneWay gebunden - 'Ebene' ist im BO read-only, eine TwoWay-Bindung
         * wuerde einen PATCH darauf versuchen.
         */
        onLevelChange: function (oEvent) {
            var oInput   = oEvent.getSource();
            var oContext = oInput.getBindingContext();

            if (!oContext) {
                return;
            }

            var sValue  = String(oEvent.getParameter("value") || "").trim();
            var iCurrent = parseInt(oContext.getProperty("Ebene"), 10);

            if (!/^\d{1,2}$/.test(sValue) || parseInt(sValue, 10) > MAX_LEVEL) {
                MessageBox.warning(this._text("msgLevelRange", [MAX_LEVEL]));
                oInput.setValue(formatter.levelText(iCurrent));
                return;
            }

            var iTarget = parseInt(sValue, 10);

            if (iTarget === iCurrent) {
                oInput.setValue(formatter.levelText(iCurrent));
                return;
            }

            this._setLevel(oContext, iTarget);
        },

        /**
         * Setzt die Zeile per RAP-Aktion auf eine absolute Ebene. Dieselbe
         * Backend-Logik wie die Pfeiltasten, nur mit Zielwert statt Schrittweite.
         */
        _setLevel: function (oContext, iTarget) {
            this._execAction(oContext, "setEbene", { Ebene: iTarget },
                             "msgMoved", [iTarget]);
        },

        _levelProperty: function (iLevel) {
            return "MatEbene" + (iLevel < 10 ? "0" + iLevel : String(iLevel));
        },

        /* ---------------------------------------------------------------- */
        /* Zeile anlegen                                                    */
        /* ---------------------------------------------------------------- */

        onAdd: function () {
            var oView = this.getView();
            var oUiModel = oView.getModel("ui");

            oUiModel.setProperty("/newMaterial", "");
            oUiModel.setProperty("/newLevel", "0");

            if (!this._pAddDialog) {
                this._pAddDialog = Fragment.load({
                    id: oView.getId(),
                    name: "de.enercon.qm009.equistruk.view.AddRow",
                    controller: this
                }).then(function (oDialog) {
                    oView.addDependent(oDialog);
                    return oDialog;
                });
            }

            this._pAddDialog.then(function (oDialog) {
                oDialog.open();
            });
        },

        onAddConfirm: function () {
            var oUiModel  = this.getView().getModel("ui");
            var sMaterial = (oUiModel.getProperty("/newMaterial") || "").trim().toUpperCase();

            if (!sMaterial) {
                MessageBox.warning(this._text("msgMaterialRequired"));
                return;
            }

            var iLevel = parseInt(oUiModel.getProperty("/newLevel"), 10) || 0;

            var oRow = {
                PlanType:     oUiModel.getProperty("/planType"),
                PlanGroup:    oUiModel.getProperty("/planGroup"),
                GroupCounter: oUiModel.getProperty("/groupCounter"),
                NodeCounter:  oUiModel.getProperty("/nodeCounter")
            };

            // Die laufende Nummer vergibt das Backend (early numbering),
            // die Materialnummer wandelt es ins interne Format.
            oRow[this._levelProperty(iLevel)] = sMaterial;

            var oBinding = this.byId("structureTable").getBinding("items");
            var that = this;

            this._closeAddDialog();
            this._setBusy(true);

            var oContext = oBinding.create(oRow, false, true);

            oContext.created().then(function () {
                that._setBusy(false);
                MessageToast.show(that._text("msgCreated"));
            }).catch(function (oError) {
                that._setBusy(false);
                that._resetChanges();
                that._showError(oError);
            });
        },

        onAddCancel: function () {
            this._closeAddDialog();
        },

        _closeAddDialog: function () {
            if (this._pAddDialog) {
                this._pAddDialog.then(function (oDialog) {
                    oDialog.close();
                });
            }
        },

        /* ---------------------------------------------------------------- */
        /* Zeile loeschen                                                   */
        /* ---------------------------------------------------------------- */

        onDelete: function (oEvent) {
            var oContext = oEvent.getSource().getBindingContext();
            if (!oContext) {
                return;
            }

            var that = this;
            var sMaterial = formatter.matnrOut(oContext.getProperty("Material"));

            MessageBox.confirm(this._text("msgConfirmDelete", [sMaterial]), {
                title: this._text("btnDelete"),
                onClose: function (sAction) {
                    if (sAction !== MessageBox.Action.OK) {
                        return;
                    }
                    that._setBusy(true);
                    oContext.delete().then(function () {
                        that._setBusy(false);
                        MessageToast.show(that._text("msgDeleted"));
                    }).catch(function (oError) {
                        that._setBusy(false);
                        that._resetChanges();
                        that._showError(oError);
                    });
                }
            });
        },

        /* ---------------------------------------------------------------- */
        /* Wertehilfe Material                                              */
        /* ---------------------------------------------------------------- */

        onMaterialValueHelp: function () {
            var oView = this.getView();

            if (!this._pMaterialDialog) {
                this._pMaterialDialog = Fragment.load({
                    id: oView.getId(),
                    name: "de.enercon.qm009.equistruk.view.MaterialValueHelp",
                    controller: this
                }).then(function (oDialog) {
                    oView.addDependent(oDialog);
                    return oDialog;
                });
            }

            this._pMaterialDialog.then(function (oDialog) {
                var oBinding = oDialog.getBinding("items");
                if (oBinding && oBinding.isSuspended()) {
                    oBinding.resume();
                }
                oDialog.open();
            });
        },

        onMaterialSearch: function (oEvent) {
            var sValue   = oEvent.getParameter("value");
            var oBinding = oEvent.getSource().getBinding("items");

            if (!oBinding) {
                return;
            }

            if (!sValue) {
                oBinding.filter([]);
                return;
            }

            oBinding.filter([new Filter({
                filters: [
                    new Filter("Material", FilterOperator.Contains, sValue.toUpperCase()),
                    new Filter("MaterialName", FilterOperator.Contains, sValue)
                ],
                and: false
            })]);
        },

        onMaterialConfirm: function (oEvent) {
            var oItem = oEvent.getParameter("selectedItem");
            if (oItem && oItem.getBindingContext()) {
                this.getView().getModel("ui").setProperty(
                    "/newMaterial",
                    oItem.getBindingContext().getProperty("Material")
                );
            }
        },

        onMaterialCancel: function () {
            /* nichts zu tun */
        },

        /* ---------------------------------------------------------------- */
        /* Helfer                                                           */
        /* ---------------------------------------------------------------- */

        /**
         * Der Gateway wendet die Konvertierungsroutinen selbst an: '4' findet
         * die Plangruppe '00000004', und Materialnummern kommen bereits ohne
         * fuehrende Nullen zurueck. Hier genuegt deshalb trimmen und gross
         * schreiben - selbst aufzufuellen wuerde die Eingabe nur von dem
         * entfernen, was der Service liefert.
         */
        _normalize: function (sValue) {
            return String(sValue || "").trim().toUpperCase();
        },

        _setBusy: function (bBusy) {
            this.getView().getModel("ui").setProperty("/busy", bBusy);
        },

        /**
         * Abgelehnte Aenderungen verwerfen, damit die Tabelle nicht in einem
         * Zustand stehen bleibt, den das Backend zurueckgewiesen hat.
         */
        _resetChanges: function () {
            var oModel = this.getView().getModel();
            if (!oModel) {
                return;
            }
            if (oModel.hasPendingChanges("$auto")) {
                oModel.resetChanges("$auto");
            }
        },

        _showError: function (oError) {
            var sMessage = this._text("msgGenericError");

            if (oError) {
                if (oError.error && oError.error.message) {
                    sMessage = oError.error.message;
                } else if (oError.message) {
                    sMessage = oError.message;
                }
            }

            MessageBox.error(sMessage);
        },

        _text: function (sKey, aArgs) {
            return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
        }
    });
});
