# Modules

A module is a folder under `Modules\` with an `.xml` that loads its files, and
a line in `Modules\Modules.xml`:

```
Modules\PetCare\PetCare.xml   Locale.lua, PetCare.lua, Options.lua, in that order
Modules\PetCare\Locale.lua    its English strings (Locales\README.md)
Modules\PetCare\PetCare.lua   the module
Modules\PetCare\Options.lua   its settings page (GetOptions)
```

Plus a `namespace="PetCare"` keyword line in every `Locales\<lang>.lua`, and
its tests in `tests\<name>_spec.lua`. The module itself:

```lua
local _, Beastkeeper = ...
local L = Beastkeeper.L

---@type BeastkeeperPetCare -- a class in annotations\Beastkeeper.lua
local M = Beastkeeper:NewModule("PetCare", "AceTimer-3.0")
M.title = L.PETCARE_TITLE
M.description = L.PETCARE_DESC
M.defaults = { profile = { threshold = 40 } }
M.command = "care"
M.commands = {
    revive = { desc = L.PETCARE_CMD_REVIVE, func = Revive }, -- Revive(module, args)
}

function M:OnEnable()
    self:RegisterEvent("UNIT_HEALTH")
end

function M:OnDisable()
    -- undo everything OnEnable did that AceEvent/AceTimer do not undo themselves
    Beastkeeper:DropToasts(self.moduleName .. ":")
end
```

`Modules\AutocastCheck\` is a complete example. What each field means is in
`annotations/Beastkeeper.lua` (`BeastkeeperModule`). The rules the core relies on:

- **The core owns the switch.** `profile.modules[name]` in `BeastkeeperDB` says
  whether a module runs; a module never calls `Enable`/`Disable` on itself.
  A module is on unless it sets `enabledByDefault = false`.
- **`OnDisable` undoes `OnEnable`.** A profile change disables every running
  module and enables the ones the new profile has on, so this is also how a
  module sees new settings. Read `self.db.profile` in `OnEnable` (or when
  needed), never keep a copy across a disable.
- **`defaults`** gives the module its own AceDB namespace as `self.db`, set
  before the module's `OnInitialize`.
- **`GetOptions`** returns an AceConfig group. It becomes a page of its own
  under Beastkeeper, greyed out while the module is off. The core sets `type`,
  `disabled`, and `name` when the group has none (the module's `title`).
  `Beastkeeper:Setting(module, key, changed)` gives an option's `get` and `set` for
  `module:Settings()[key]`; `changed` runs after a set while the module is on.
- **`self:Print(...)`** says a line in chat; it names the module in the
  `BEASTKEEPER_PRINT` message ([04-hooking.md](04-hooking.md)).
- Every module embeds AceEvent-3.0; anything else it lists in `NewModule`
  and in `embeds.xml` / `.pkgmeta`.
