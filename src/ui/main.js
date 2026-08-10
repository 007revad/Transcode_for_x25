Ext.namespace("SYNO.SDS.TranscodeDrivers");

// -----------------------------------------------------------------
// App entry point
// -----------------------------------------------------------------
Ext.define("SYNO.SDS._ThirdParty.App.TranscodeDrivers", {
    extend: "SYNO.SDS.AppInstance",
    appWindowName: "SYNO.SDS.TranscodeDrivers.MainWindow",
    constructor: function() {
        this.callParent(arguments);
    }
});

// -----------------------------------------------------------------
// Shared API helper
// -----------------------------------------------------------------
SYNO.SDS.TranscodeDrivers.API_PATH = "/webman/3rdparty/TranscodeDrivers/api.cgi";

SYNO.SDS.TranscodeDrivers.apiCall = function(action, params, callback) {
    Ext.Ajax.request({
        url: SYNO.SDS.TranscodeDrivers.API_PATH,
        method: "GET",
        params: Ext.apply({ action: action, _ts: new Date().getTime() }, params || {}),
        success: function(response) {
            var resp;
            try {
                resp = Ext.decode(response.responseText);
            } catch (e) {
                resp = { success: false, message: "Bad response from api.cgi" };
            }
            callback(resp);
        },
        failure: function() {
            callback({ success: false, message: "Request to api.cgi failed" });
        }
    });
};

// -----------------------------------------------------------------
// Main window - read-only log viewer. No Refresh/Clear/Settings:
// the package has no Stop button, so there's nothing to re-run and
// clearing the log would need a reboot (or SSH stop/start) to see
// a fresh one anyway. See TranscodeDrivers NOTES.md if that changes.
// -----------------------------------------------------------------
Ext.define("SYNO.SDS.TranscodeDrivers.MainWindow", {
    extend: "SYNO.SDS.AppWindow",

    constructor: function(a) {
        this.appInstance = a.appInstance;
        SYNO.SDS.TranscodeDrivers.MainWindow.superclass.constructor.call(this, Ext.apply({
            layout: "fit",
            resizable: true,
            cls: "syno-app-win transcodedrivers-win",
            maximizable: true,
            minimizable: true,
            showHelp: false,
            width: 640,
            height: 480,
            html: this.buildHtml(),
            listeners: {
                afterrender: {
                    fn: this.onAfterRender,
                    scope: this
                }
            }
        }, a));
    },

    buildHtml: function() {
        return [
            '<style>',
            '  .transcodedrivers-log { -webkit-user-select: text; -moz-user-select: text; -ms-user-select: text; user-select: text; }',
            '  .transcodedrivers-body { display:flex; flex-direction:column; height:100%; padding:8px; box-sizing:border-box; }',
            '  .transcodedrivers-status { flex:0 0 auto; padding-bottom:8px; font-size:13px; color:#888; }',
            '  .transcodedrivers-log { flex:1 1 auto; margin:0; overflow:auto; background:#161eb5; color:#ddd; padding:8px; font-family:Verdana,Arial,sans-serif; font-size:12px; white-space:pre-wrap; border-radius:4px; }',
            '</style>',
            '<div class="transcodedrivers-body">',
            '  <div class="transcodedrivers-status"></div>',
            '  <pre class="transcodedrivers-log">Loading&hellip;</pre>',
            '</div>'
        ].join("");
    },

    onAfterRender: function() {
        var el = this.body.dom;
        this.logEl = el.querySelector(".transcodedrivers-log");
        this.statusEl = el.querySelector(".transcodedrivers-status");

        // DSM's desktop chrome suppresses the native right-click menu
        // globally. Stopping propagation here keeps it from reaching
        // that handler, so Copy etc. shows up normally over our content.
        Ext.fly(el).on("contextmenu", function(ev) { ev.stopPropagation(); });

        this.loadLog();
    },

    setStatus: function(msg) {
        if (this.statusEl) { this.statusEl.textContent = msg || ""; }
    },

    loadLog: function() {
        this.setStatus("Loading\u2026");
        SYNO.SDS.TranscodeDrivers.apiCall("getlog", {}, (function(resp) {
            this.setStatus("");
            if (resp && resp.success) {
                this.showLog(resp.result);
            } else {
                this.showLog((resp && resp.message) || "(no log available)");
            }
        }).createDelegate(this));
    },

    showLog: function(text) {
        if (this.logEl) {
            this.logEl.textContent = text || "(log is empty)";
            this.logEl.scrollTop = this.logEl.scrollHeight;
        }
    },

    onClose: function() {
        SYNO.SDS.TranscodeDrivers.MainWindow.superclass.onClose.apply(this, arguments);
        this.doClose();
        return true;
    }
});
