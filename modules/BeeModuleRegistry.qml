pragma Singleton
import QtQuick

QtObject {
    id: registry

    readonly property int apiVersion: 1
    readonly property int mayaDashSlots: 8

    property ListModel beeBarModules: ListModel { id: _beeBarModules }
    property ListModel mayaDashModules: ListModel { id: _mayaDashModules }

    function _sanitizeText(v, fallback) {
        var s = (v === undefined || v === null) ? "" : (v + "").trim()
        return s.length > 0 ? s : fallback
    }

    function _normalizeOrder(v, fallback) {
        var n = Number(v)
        if (isNaN(n)) return fallback
        return Math.max(0, Math.floor(n))
    }

    function _upsert(model, moduleId, payload) {
        for (var i = 0; i < model.count; ++i) {
            if (model.get(i).moduleId === moduleId) {
                model.set(i, payload)
                return i
            }
        }
        model.append(payload)
        return model.count - 1
    }

    function _sortByOrder(model) {
        var rows = []
        for (var i = 0; i < model.count; ++i) rows.push(model.get(i))
        rows.sort(function(a, b) {
            if (a.order === b.order) return a.moduleId < b.moduleId ? -1 : (a.moduleId > b.moduleId ? 1 : 0)
            return a.order - b.order
        })
        model.clear()
        for (var j = 0; j < rows.length; ++j) model.append(rows[j])
    }

    function registerBeeBarModule(spec) {
        if (!spec || typeof spec !== "object") return false
        var moduleId = _sanitizeText(spec.id, "")
        if (!moduleId) {
            console.warn("BeeModuleRegistry: BeeBar module id is required")
            return false
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
