local _, ns = ...

-- What the client's game has of the hunter pet's old mechanics, found by asking for the API, not
-- by version: WoW: Forever, Classic Era and Burning Crusade have them all; Wrath and later lack
-- training points (and so learning abilities from beasts), Cataclysm and later pet happiness and
-- ammo. A module names what it needs in `requires`; without it, it stays off (Beastkeeper:IsModuleOn).

---@type Addon
local Addon = ns

---Works out Beastkeeper.features; at OnInitialize, when every file has loaded.
function Addon:FindFeatures()
    self.features = {
        happiness = self.C.Has("PetInfo", "GetPetHappiness"),
        ammo = INVSLOT_AMMO ~= nil,
        beastTraining = self.C.Has("PetInfo", "GetPetTrainingPoints"),
        -- Beastkeeper's own data of which beasts teach what (Data\<client>\Beasts.lua).
        beastData = next(self.data.beasts) ~= nil,
    }
end

---Whether the client has everything a module needs.
---@param name string
---@return boolean
function Addon:IsModuleUsable(name)
    for _, feature in ipairs(self.modules[name].requires or {}) do
        if not self.features[feature] then return false end
    end
    return true
end
