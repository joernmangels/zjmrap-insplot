sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/routing/History",
    "sap/ui/model/json/JSONModel",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator",
    "de/enercon/qm009/strukrun/model/formatter"
], (Controller, History, JSONModel, Filter, FilterOperator, formatter) => {
    "use strict";

    return Controller.extend("de.enercon.qm009.strukrun.controller.RunLog", {
        formatter: formatter,

        onInit() {
            this.getView().setModel(new JSONModel({ runId: "", notFound: false, logCount: 0 }), "view");

            // Die View wird nur einmal erzeugt und dann wiederverwendet -
            // die RunId deshalb bei jedem Treffer der Route neu lesen
            this.getOwnerComponent().getRouter()
                .getRoute("RouteRunLog")
                .attachPatternMatched(this._onRouteMatched, this);
        },

        _onRouteMatched(oEvent) {
            const sRunId = oEvent.getParameter("arguments").RunId;
            const oViewModel = this.getView().getModel("view");
            oViewModel.setProperty("/runId", sRunId);
            oViewModel.setProperty("/notFound", false);

            this._bindHeader(sRunId);
            this._bindLog(sRunId);
        },

        /**
         * Kopf an die erste Protokollzeile binden. Zusammengesetzter
         * Schluessel; Edm.Guid steht in V4 ohne Anfuehrungszeichen.
         */
        _bindHeader(sRunId) {
            this.getView().byId("runHeader").bindElement({
                path: `/StrukLog(RunId=${sRunId},Seq=1)`,
                parameters: { $expand: "_Lot($select=Material,MaterialText)" },
                events: {
                    // Kein Satz (unbekannte RunId) kommt als Fehler zurueck
                    dataReceived: (oEvent) => {
                        if (oEvent.getParameter("error")) {
                            this.getView().getModel("view").setProperty("/notFound", true);
                        }
                    }
                }
            });
        },

        onLogTableUpdated(oEvent) {
            this.getView().getModel("view").setProperty("/logCount", oEvent.getParameter("total"));
        },

        _bindLog(sRunId) {
            const oBinding = this.byId("logTable").getBinding("items");
            oBinding.filter(new Filter("RunId", FilterOperator.EQ, sRunId));
            // Beim ersten Aufruf ist das Binding noch angehalten (suspended in der View)
            if (oBinding.isSuspended()) {
                oBinding.resume();
            }
        },

        onNavBack() {
            // Zurueck per Browser-Historie, damit kein doppelter Eintrag
            // entsteht; nach einem Deep-Link ohne Vorgeschichte zur Liste
            if (History.getInstance().getPreviousHash() !== undefined) {
                window.history.go(-1);
            } else {
                this.getOwnerComponent().getRouter().navTo("RouteLotList", {}, true);
            }
        }
    });
});
