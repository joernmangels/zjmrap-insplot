/*global QUnit*/

sap.ui.define([
	"de/enercon/qm009/strukrun/controller/LotList.controller"
], function (Controller) {
	"use strict";

	QUnit.module("LotList Controller");

	QUnit.test("I should test the LotList controller", function (assert) {
		var oAppController = new Controller();
		oAppController.onInit();
		assert.ok(oAppController);
	});

});
