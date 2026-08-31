sap.ui.define([], function () {
    "use strict";

    // Tabelle ZJMQM_QM009_Q hat die Ebenen 0 bis 19 (MAT_EBENE0..MAT_EBENE19)
    var MAX_LEVEL = 19;

    return {

        MAX_LEVEL: MAX_LEVEL,

        /**
         * Materialnummer in Ausgabeformat: fuehrende Nullen bei rein numerischen
         * Nummern entfernen (entspricht CONVERSION_EXIT_MATN1_OUTPUT).
         */
        matnrOut: function (sMatnr) {
            if (!sMatnr) {
                return "";
            }
            var s = String(sMatnr).trim();
            return /^\d+$/.test(s) ? s.replace(/^0+(?=\d)/, "") : s;
        },

        /**
         * Breite des Einrueckungs-Platzhalters vor dem Baum-Konnektor.
         * 2rem je Ebene: deutlich sichtbare Spruenge, und selbst Ebene 19
         * bleibt mit 38rem gut innerhalb der Materialspalte.
         */
        indent: function (iLevel) {
            var i = parseInt(iLevel, 10);
            if (isNaN(i) || i < 0 || i > MAX_LEVEL) {
                return "0rem";
            }
            return (i * 2) + "rem";
        },

        /**
         * Ebene als Text; 99 ist der Marker der CDS-Sicht fuer "keine Ebene belegt".
         */
        levelText: function (iLevel) {
            var i = parseInt(iLevel, 10);
            return (isNaN(i) || i > MAX_LEVEL) ? "-" : String(i);
        },

        levelState: function (iLevel) {
            var i = parseInt(iLevel, 10);
            return (isNaN(i) || i > MAX_LEVEL) ? "Error" : "Information";
        },

        canOutdent: function (iLevel) {
            var i = parseInt(iLevel, 10);
            return !isNaN(i) && i > 0 && i <= MAX_LEVEL;
        },

        canIndent: function (iLevel) {
            var i = parseInt(iLevel, 10);
            return !isNaN(i) && i >= 0 && i < MAX_LEVEL;
        }
    };
});
