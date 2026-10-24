local _, ns = ...

-- What the client's game has of the hunter pet's old mechanics, found by asking for the API, not
-- by version: WoW: Forever, Classic Era and Burning Crusade have them all; Wrath and later lack
-- training points (and so learning abilities from beasts), Cataclysm and later pet happiness and
-- ammo. A module names what it needs in `requires`; without it, it stays off (Kennel:IsModuleOn).

---@type Kennel
local Kennel = ns

---Works out Kennel.features; at OnInitialize, when every file has loaded.
function Kennel:FindFeatures()
    self.features = {
        happiness = ((C_PetInfo and C_PetInfo.GetPetHappiness) or GetPetHappiness) ~= nil,
        ammo = INVSLOT_AMMO ~= nil,
        beastTraining = ((C_PetInfo and C_PetInfo.GetPetTrainingPoints) or GetPetTrainingPoints) ~= nil,
    }
end

---Whether the client has everything a module needs.
---@param name string
---@return boolean
function Kennel:IsModuleUsable(name)
    for _, feature in ipairs(self.modules[name].requires or {}) do
        if not self.features[feature] then return false end
    end
    return true
end
