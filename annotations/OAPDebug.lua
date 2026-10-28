---@meta
-- OAP Debug's global table, as far as Beastkeeper calls it (Core\Debug.lua). Every call catches its
-- own errors. From its in-game Developer usage page.

---@class OAPDebugApi
---@field Register fun(name: string, opts: { title: string?, folder: string?, icon: (string|number)? }): string
---@field Log fun(source: string, msg: string, level: "error"|"warn"|"info"|"debug", ...: any)
---@field Chat fun(source: string, msg: string)
---@field Count fun(source: string, name: string, n: number?)
---@field Time fun(source: string, name: string, fn: fun(...): ..., ...: any): ...

-- _DebugLog's global table (DLAPI), as far as Beastkeeper calls it (Core\Debug.lua). From its
-- Modules\DLGUI_debuglog_api.lua and DLGUI_debuglog_tab.lua.

---@class DebugLogApi
---@field DebugLog fun(tab: string, fmt: string, ...: any) adds string.format(fmt, ...) to the tab, made on first use
