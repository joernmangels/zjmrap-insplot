sap.ui.define([
    "sap/ui/core/UIComponent",
    "sap/ui/Device",
    "sap/ui/core/Messaging",
    "sap/ui/model/json/JSONModel"
], function (UIComponent, Device, Messaging, JSONModel) {
    "use strict";

    return UIComponent.extend("de.enercon.qm009.equistruk.Component", {

        metadata: {
            manifest: "json",
            interfaces: ["sap.ui.core.IAsyncContentCreation"]
        },

        init: function () {
            UIComponent.prototype.init.apply(this, arguments);

            this.setModel(new JSONModel({
                isPhone: Device.system.phone,
                isDesktop: Device.system.desktop
            }), "device");

            // Meldungen des Backends (SAP__Messages) - hierueber erscheinen
            // die Warnungen der RAP-Pruefungen in der Oberflaeche.
            this.setModel(Messaging.getMessageModel(), "message");
        },

        getContentDensityClass: function () {
            if (this._sContentDensityClass === undefined) {
                this._sContentDensityClass = Device.support.touch ? "sapUiSizeCozy" : "sapUiSizeCompact";
            }
            return this._sContentDensityClass;
        }
    });
});
