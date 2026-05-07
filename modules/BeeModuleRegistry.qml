pragma Singleton
import QtQuick

QtObject {
    id: registry

    readonly property int apiVersion: 1
    readonly property int mayaDashSlots: 8

    // ListModels with roles pre-seeded via empty ListElements (all string/number to avoid QML6 bool issues)
    property ListModel beeBarModules: ListModel { id: _beeBarModules }
    property ListModel mayaDashModules: ListModel { id: _mayaDashModules }

    // Track whether models have been seeded with their role template
    property bool _barSeeded: false
    property bool _dashSeeded: false

    function _sanitizeText(v, fallback) {
        var s = (v === undefined || v === null) ? "" : (v + "").trim()
        return s.length > 0 ? s : fallback
    }

    function _normalizeOrder(v, fallback) {
        var n = Number(v)
        if (isNaN(n)) return fallback
        return Math.max(0, Math.floor(n))
    }

    function _seedModel(model, template) {
        // Append a template row to establish ListModel roles,
        // then immediately remove it. This ensures QML knows
        // all role names before real data is appended.
        model.append(template)
        model.remove(0)
    }

    function _upsert(model, moduleId, payload) {
        for (var i = 0; i < model.count; ++i) {
            if (model.get(i).moduleId === moduleId) {
                // Use set() to update in-place — preserves roles
                var keys = Object.keys(payload)
                for (var k = 0; k < keys.length; ++k) {
                    model.setProperty(i, keys[k], payload[keys[k]])
                }
                return i
            }
        }
        model.append(payload)
        return model.count - 1
    }

    function _sortByOrder(model) {
        // Sort in-place using swap instead of clear/append
        // to preserve ListModel roles
        var n = model.count
        for (var i = 0; i < n - 1; ++i) {
            for (var j = 0; j < n - i - 1; ++j) {
                var a = model.get(j)
                var b = model.get(j + 1)
                if (a.order > b.order || (a.order === b.order && a.moduleId > b.moduleId)) {
                    // Swap via setProperty
                    var aKeys = ["moduleId", "title", "icon", "action", "order", "enabled", "source",
                                 "slot", "subtitle", "detail", "highlighted"]
                    var aVals = {}
                    var bVals = {}
                    for (var k = 0; k < aKeys.length; ++k) {
                        var key = aKeys[k]
                        try { aVals[key] = a[key] } catch(e) { aVals[key] = undefined }
                        try { bVals[key] = b[key] } catch(e) { bVals[key] = undefined }
                    }
                    for (var k = 0; k < aKeys.length; ++k) {
                        var key = aKeys[k]
                        if (aVals[key] !== undefined) model.setProperty(j, key, bVals[key])
                        if (bVals[key] !== undefined) model.setProperty(j + 1, key, aVals[key])
                    }
                }
            }
        }
    }

    function registerBeeBarModule(spec) {
        if (!spec || typeof spec !== "object") return false
        var moduleId = _sanitizeText(spec.id, "")
        if (!moduleId) {
            console.warn("BeeModuleRegistry: BeeBar module id is required")
            return false
        }

        // Seed model roles on first registration
        if (!_barSeeded) {
            _seedModel(_beeBarModules, {
                moduleId: "", title: "", icon: "", action: "none",
                order: 0, enabled: true, source: "internal"
            })
            _barSeeded = true
        }

        var payload = {
            moduleId: moduleId,
            title: _sanitizeText(spec.title, moduleId),
            icon: _sanitizeText(spec.icon, "🐝"),
            action: _sanitizeText(spec.action, "none"),
            order: _normalizeOrder(spec.order, 100),
            enabled: spec.enabled !== false,
            source: _sanitizeText(spec.source, "internal")
        }

        _upsert(_beeBarModules, moduleId, payload)
        _sortByOrder(_beeBarModules)
        return true
    }

    function registerMayaDashModule(spec) {
        if (!spec || typeof spec !== "object") return false
        var moduleId = _sanitizeText(spec.id, "")
        if (!moduleId) {
            console.warn("BeeModuleRegistry: MayaDash module id is required")
            return false
        }

        var slot = _normalizeOrder(spec.slot, 0)
        if (slot < 0 || slot >= mayaDashSlots) {
            console.warn("BeeModuleRegistry: MayaDash slot must be between 0 and", mayaDashSlots - 1)
            return false
        }

        // Seed model roles on first registration
        if (!_dashSeeded) {
            _seedModel(_mayaDashModules, {
                moduleId: "", slot: 0, title: "", subtitle: "",
                icon: "", detail: "", action: "none",
                highlighted: false, order: 0, enabled: true, source: "internal"
            })
            _dashSeeded = true
        }

        var payload = {
            moduleId: moduleId,
            slot: slot,
            title: _sanitizeText(spec.title, moduleId),
            subtitle: _sanitizeText(spec.subtitle, ""),
            icon: _sanitizeText(spec.icon, "🐝"),
            detail: _sanitizeText(spec.detail, ""),
            action: _sanitizeText(spec.action, "none"),
            highlighted: spec.highlighted === true,
            order: _normalizeOrder(spec.order, slot),
            enabled: spec.enabled !== false,
            source: _sanitizeText(spec.source, "internal")
        }

        _upsert(_mayaDashModules, moduleId, payload)
        _sortByOrder(_mayaDashModules)
        return true
    }

    function unregisterModule(id) {
        var key = _sanitizeText(id, "")
        if (!key) return

        for (var i = _beeBarModules.count - 1; i >= 0; --i) {
            if (_beeBarModules.get(i).moduleId === key) _beeBarModules.remove(i)
        }
        for (var j = _mayaDashModules.count - 1; j >= 0; --j) {
            if (_mayaDashModules.get(j).moduleId === key) _mayaDashModules.remove(j)
        }
    }

    function clearAll() {
        _beeBarModules.clear()
        _mayaDashModules.clear()
        _barSeeded = false
        _dashSeeded = false
    }

    function mayaDashCellAt(slot) {
        var s = _normalizeOrder(slot, -1)
        for (var i = 0; i < _mayaDashModules.count; ++i) {
            var row = _mayaDashModules.get(i)
            if (row.enabled && row.slot === s) return row
        }
        return null
    }
}