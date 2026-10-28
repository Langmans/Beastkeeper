local _, ns = ...

-- What the client blocks in combat (changing a secure button, editing a macro) runs now outside
-- combat, or once combat ends. Kept on the core, since a module's own events are dropped when it is
-- switched off, and switching a module off in combat is exactly when this is needed.

---@type Addon
local Addon = ns

-- What waits for the end of combat, by key: asking again for a key replaces what waited.
---@type table<string, fun()>
local waiting = {}

---Runs `fn` now, or after combat; per key only the last one asked runs.
---@param key string
---@param fn fun()
function Addon:OutOfCombat(key, fn)
    if not InCombatLockdown() then
        fn()
        return
    end
    waiting[key] = fn
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "RunWaiting")
end

---Combat ended: runs what waited for it.
function Addon:RunWaiting()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    local due = waiting
    waiting = {}
    for _, fn in pairs(due) do
        fn()
    end
end
