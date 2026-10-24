-- CareButton: one key for Mend Pet, Revive Pet and Call Pet that remembers a dead pet, its toasts,
-- what failed casts teach it, and the KennelCare macro that follows it.

local MEND, REVIVE, CALL = 136, 982, 883
-- /use rather than /cast: it casts a spell just the same, and leaves more of the 255 characters.
local ALIVE_CAST = "/use [mod:shift][@pet,dead] Revive Pet; [mod:ctrl][nopet] Call Pet; Mend Pet"
local DEAD_CAST = "/use [mod:ctrl] Call Pet; [mod:shift][@pet,dead][nopet] Revive Pet; Mend Pet"
local ALIVE = "#showtooltip\n" .. ALIVE_CAST
local DEAD = "#showtooltip\n" .. DEAD_CAST

---A saved file with these CareButton settings (profile) and per-character values (char).
local function saved(profile, char)
    return {
        profileKeys = { ["Langmans - Doomhowl"] = "Default" },
        namespaces = {
            CareButton = {
                profiles = profile and { Default = profile } or nil,
                char = char and { ["Langmans - Doomhowl"] = char } or nil,
            },
        },
    }
end

describe("CareButton", function()
    describe("the button", function()
        it("gives a living pet Mend Pet; Shift forces Revive Pet and Ctrl Call Pet", function()
            local client = NewClient():login()
            assert.are.equal("Mend Pet", client:press())
            assert.are.equal("Revive Pet", client:press({ shift = true }))
            assert.are.equal("Call Pet", client:press({ ctrl = true }))
        end)

        it("calls a pet that is not known to be dead", function()
            assert.are.equal("Call Pet", NewClient({ noPet = true }):login():press())
        end)

        it("revives a pet that died, also once its body is gone, also in combat", function()
            local client = NewClient():login():enterCombat()
            client:petDies()
            assert.are.equal("Revive Pet", client:press(), "the body is still there")
            client:petGone()
            assert.are.equal("Revive Pet", client:press(), "a plain macro would call here")
            assert.are.equal("Call Pet", client:press({ ctrl = true }))
            assert.are.same({}, client.blocked, "only secure code changed the button")
            client:petBack()
            assert.are.equal("Mend Pet", client:press())
            client:petGone()
            assert.are.equal("Call Pet", client:press(), "a living pet dismissed is called again")
        end)

        it("remembers the death per character, across a relog", function()
            local client = NewClient():login():petDies()
            client:logout()
            local relogged = NewClient({ noPet = true, saved = Saved() }):login()
            assert.are.equal("Revive Pet", relogged:press())
        end)

        it("counts a broken saved value as alive", function()
            local client = NewClient({ noPet = true, saved = saved(nil, { petDead = "yes" }) }):login()
            assert.are.equal("Call Pet", client:press())
        end)

        it("is set up once combat ends when the module starts in combat", function()
            local client = NewClient({ inCombat = true }):login()
            assert.is_nil(client:press(), "nothing set up yet")
            assert.are.same({}, client.blocked, "nothing was tried")
            client:leaveCombat()
            assert.are.equal("Mend Pet", client:press())
        end)

        it("acts on the key's release and answers to up and down clicks", function()
            NewClient():login()
            assert.are.same({ "AnyUp", "AnyDown" }, KennelCareButton.clicks)
            assert.is_false(KennelCareButton.attributes.useOnKeyDown)
        end)

        it("uses the client's spell names, or English ones without them", function()
            local german = NewClient({ locale = "deDE" }):login()
            assert.are.equal("Tier heilen", german:press())
            assert.are.equal("Tier wiederbeleben", german:press({ shift = true }))
            assert.are.equal("Mend Pet", NewClient({ noSpellAPI = true }):login():press())
        end)

        it("is not set up on another class", function()
            local client = NewClient({ class = "MAGE" }):login()
            assert.is_nil(client:press())
            assert.are.same({}, client.drivers)
        end)

        it("has a named key binding", function()
            NewClient():login()
            assert.are.equal(
                "Care Button: mend, revive or call pet",
                _G["BINDING_NAME_CLICK KennelCareButton:LeftButton"]
            )
        end)

        it("does nothing while the module is off, and works again when it is on", function()
            local client = NewClient():login()
            client.Kennel:SetModuleOn("CareButton", false)
            assert.is_nil(client:press())
            assert.are.same({}, client.drivers)
            client.Kennel:SetModuleOn("CareButton", true)
            assert.are.equal("Mend Pet", client:press())
        end)

        it("is switched off and on again after combat when the module is switched in combat", function()
            local client = NewClient():login():enterCombat()
            client.Kennel:SetModuleOn("CareButton", false)
            assert.are.equal("Mend Pet", client:press(), "it cannot change in combat")
            assert.are.same({}, client.blocked)
            client:leaveCombat()
            assert.is_nil(client:press())
        end)
    end)

    describe("the toasts", function()
        it("say the pet died, with the spell's icon and the key to press", function()
            local client = NewClient():login()
            client.bindings["CLICK KennelCareButton:LeftButton"] = "F"
            client:petDies()
            local toast = client:toast()
            assert.are.equal("Your pet is dead", client:toastTitle())
            assert.are.equal(132163, toast.Icon.texture)
            assert.are.equal("The button casts Revive Pet now, also once the body is gone.", toast.Text.text)
            assert.are.equal("Press <F>.", toast.Hint.text)
        end)

        it("name the macro when there is no key binding", function()
            local client = NewClient():login():petDies()
            assert.are.equal("Press your KennelCare macro.", client:toast().Hint.text)
        end)

        it("go away when the pet lives again", function()
            local client = NewClient():login():petDies():petGone():petBack():animate(1)
            assert.is_false(client:toast().shown)
        end)

        it("can be switched off; the button still switches", function()
            local client = NewClient({ saved = saved({ died = false }) }):login():petDies():petGone()
            assert.is_nil(client:toastTitle())
            assert.are.equal("Revive Pet", client:press())
        end)

        it("say at the pull that there is no pet, or that it is still dead", function()
            local client = NewClient({ noPet = true }):login():enterCombat()
            assert.are.equal("You have no pet out", client:toastTitle())
            assert.are.equal("Combat started without your pet.", client:toast().Text.text)
            client:petBack():animate(1)
            assert.is_false(client:toast().shown, "the pet came")
            client:petDies():petGone():leaveCombat()
            client.Kennel:HideToast()
            client:enterCombat()
            assert.are.equal("Your pet is dead", client:toastTitle())
        end)

        it("wait, with the button and the macros, until the hunter knows Call Pet", function()
            local client = NewClient({ noPet = true })
            client.unknownSpells[883] = true -- a hunter below level 10
            client:login():enterCombat()
            assert.is_nil(client:toastTitle(), "no pet to miss yet")
            client:leaveCombat()
            assert.is_false(_G.KennelCareButton:IsShown(), "no button on screen")
            assert.are.equal(0, #client.charMacros, "no macros yet")
            client.unknownSpells[883] = nil
            client:fire("SPELLS_CHANGED")
            assert.is_true(_G.KennelCareButton:IsShown())
            assert.is_true(#client.charMacros > 0)
            client:enterCombat()
            assert.are.equal("You have no pet out", client:toastTitle())
        end)

        it("say nothing at the pull with a pet out, or when switched off", function()
            assert.is_nil(NewClient():login():enterCombat():toastTitle())
            local client = NewClient({ noPet = true, saved = saved({ nopet = false }) }):login():enterCombat()
            assert.is_nil(client:toastTitle())
            client = NewClient({ noPet = true, saved = saved({ died = false }, { petDead = true }) })
            assert.is_nil(client:login():enterCombat():toastTitle())
        end)

        it("say at the pull that the pet is on Passive, until its stance changes", function()
            local client = NewClient():login()
            client.petBar[6] = { token = "PET_MODE_PASSIVE", active = true }
            client:enterCombat()
            assert.are.equal("Your pet is on Passive", client:toastTitle())
            assert.are.equal(
                "It will not attack: set it to Defensive or Aggressive on the pet bar.",
                client:toast().Text.text
            )
            assert.are.equal("Interface\\Icons\\Ability_Seal", client:toast().Icon.texture)
            client.petBar[6].active = false
            client:petBarUpdate():animate(1)
            assert.is_false(client:toast().shown)
        end)

        it("say nothing at the pull about a stance that is not Passive, or when switched off", function()
            local client = NewClient():login()
            client.petBar[6] = { token = "PET_MODE_PASSIVE", active = false }
            assert.is_nil(client:enterCombat():toastTitle())
            client = NewClient({ saved = saved({ passive = false }) }):login()
            client.petBar[6] = { token = "PET_MODE_PASSIVE", active = true }
            assert.is_nil(client:enterCombat():toastTitle())
            client = NewClient({ noPetBarAPI = true }):login()
            assert.is_nil(client:enterCombat():toastTitle(), "no pet bar to read")
        end)

        it("say once that the pet's health is low, again only after it went back up", function()
            local client = NewClient():login()
            client:petHealth(60)
            assert.is_nil(client:toastTitle())
            client:petHealth(40)
            assert.are.equal("Your pet is at 40% health", client:toastTitle())
            client.Kennel:HideToast()
            client:petHealth(30)
            assert.is_nil(client:toastTitle(), "still low: no second toast")
            client:petHealth(80)
            client:petHealth(20)
            assert.are.equal("Your pet is at 20% health", client:toastTitle())
        end)

        it("take the low toast away when health is back up or the pet dies", function()
            local client = NewClient():login():petHealth(10)
            client:petHealth(90):animate(1)
            assert.is_false(client:toast().shown)
            client:petHealth(10)
            client:petDies():animate(1)
            assert.are.equal("Your pet is dead", client:toastTitle())
        end)

        it("decide nothing on hidden health until it can be read", function()
            local client = NewClient():login()
            client.healthSecret = true
            client:petHealth(10)
            assert.is_nil(client:toastTitle())
            client.healthSecret = false
            client:fire("UNIT_MAXHEALTH", "pet")
            assert.are.equal("Your pet is at 10% health", client:toastTitle())
        end)

        it("have no low toast at 0%, and look only at the pet's health", function()
            local client = NewClient({ saved = saved({ low = 0 }) }):login():petHealth(5)
            assert.is_nil(client:toastTitle())
            client = NewClient():login()
            client.pet.health = 10
            client:fire("UNIT_HEALTH", "target")
            assert.is_nil(client:toastTitle())
        end)

        it("play the pet's death sound, wound cry and call, or the raid warning", function()
            local client = NewClient():login():petHealth(10)
            assert.are.same({ file = 562395, channel = "Master" }, client.sounds[1], "wound")
            client:petDies():animate(1) -- the dead toast waits for the low one to go, then plays
            assert.are.same({ file = 562391, channel = "Master" }, client.sounds[2], "death")
            client = NewClient({ noPet = true }):login():enterCombat()
            assert.are.same({ kit = 8959, channel = "Master" }, client.sounds[1], "no pet, no family")
            client = NewClient({ saved = saved({ sound = "warning" }) }):login():petDies()
            assert.are.same({ kit = 8959, channel = "Master" }, client.sounds[1])
            client = NewClient({ saved = saved({ sound = "off" }) }):login():petDies()
            assert.are.same({}, client.sounds)
        end)

        it("are four kinds, each with a look of its own", function()
            local kinds = NewClient():login().Kennel:ToastTypes()
            assert.are.equal("Care Button: pet died", kinds["CareButton:dead"])
            assert.are.equal("Care Button: no pet at the pull", kinds["CareButton:nopet"])
            assert.are.equal("Care Button: low health", kinds["CareButton:low"])
            assert.are.equal("Care Button: pet on Passive at the pull", kinds["CareButton:passive"])
        end)

        it("go away when the module is switched off", function()
            local client = NewClient():login():petDies()
            client.Kennel:SetModuleOn("CareButton", false)
            client:animate(1)
            assert.is_false(client:toast().shown)
        end)
    end)

    describe("on screen", function()
        local MEND_ICON, REVIVE_ICON, CALL_ICON = 132179, 132163, 132161

        ---The mouse over the button: the tooltip's title and its lines' texts.
        local function hover(client)
            local button = _G.KennelCareButton
            client.tooltipLines, GameTooltip.text = {}, nil
            button:GetScript("OnEnter")(button)
            local texts = {}
            for _, line in ipairs(client.tooltipLines) do
                texts[#texts + 1] = line.text
            end
            return GameTooltip.text, texts
        end

        it("shows the spell it casts now, with a border to match, below the pet frame", function()
            local client = NewClient()
            local colors = {}
            client.Kennel:RegisterButtonSkin("record", {
                name = "Record",
                priority = 100,
                Style = function(button)
                    return function(r, g, b)
                        colors[button] = { r, g, b }
                    end
                end,
            })
            client:login()
            local button = _G.KennelCareButton
            assert.is_true(button:IsShown())
            assert.are.same({ "TOPLEFT", PetFrame, "BOTTOMLEFT", 0, -4 }, { button:GetPoint() })
            assert.are.equal(MEND_ICON, button.icon.texture)
            assert.are.same({ 0, 1, 0 }, colors[button])
            client:petDies()
            assert.are.equal(REVIVE_ICON, button.icon.texture)
            assert.are.same({ 1, 0, 0 }, colors[button])
            client:petGone()
            assert.are.equal(REVIVE_ICON, button.icon.texture, "the body gone: still dead")
            client:petBack()
            assert.are.equal(MEND_ICON, button.icon.texture)
            NewClient({ noPet = true }):login()
            assert.are.equal(CALL_ICON, _G.KennelCareButton.icon.texture)
        end)

        it("names the spell and the modifiers in its tooltip", function()
            local title, lines = hover(NewClient():login())
            assert.are.equal("Care Button", title)
            assert.are.same({ "Mend Pet", "Shift: Revive Pet. Ctrl: Call Pet. Shift-drag to move." }, lines)
            _G.KennelCareButton:GetScript("OnLeave")(_G.KennelCareButton)
            assert.is_false(GameTooltip:IsShown())
        end)

        it("moves with Shift held, keeps its place, and goes back from the page", function()
            local client = NewClient():login()
            local button = _G.KennelCareButton
            button:GetScript("OnDragStart")(button)
            assert.is_falsy(button.moving)
            client.mods.shift = true
            button:GetScript("OnDragStart")(button)
            button:GetScript("OnDragStop")(button)
            client:logout()
            client = NewClient({ saved = Saved() }):login()
            assert.are.same({ "TOPLEFT", UIParent, "BOTTOMLEFT", 300, 700 }, { _G.KennelCareButton:GetPoint() })
            client.Kennel:GetOptionsTable().args.CareButton.args.resetPosition.func()
            assert.are.same({ "TOPLEFT", PetFrame, "BOTTOMLEFT", 0, -4 }, { _G.KennelCareButton:GetPoint() })
        end)

        it("hides with its switch or the module off, after combat", function()
            local client = NewClient():login()
            local args = client.Kennel:GetOptionsTable().args.CareButton.args
            client:enterCombat()
            args.visible.set({}, false)
            assert.is_true(_G.KennelCareButton:IsShown(), "a secure button stays in combat")
            client:leaveCombat()
            assert.is_false(_G.KennelCareButton:IsShown())
            args.visible.set({}, true)
            assert.is_true(_G.KennelCareButton:IsShown())
            client.Kennel:SetModuleOn("CareButton", false)
            assert.is_false(_G.KennelCareButton:IsShown())
        end)
    end)

    describe("the low health marker", function()
        ---The marker's alpha as the client would draw it: a hidden one still carries its value.
        local function alpha()
            local value = _G.KennelLowHealthMarker.alpha
            return type(value) == "table" and value.secret or value
        end

        it("lights up beside the pet frame below the low line", function()
            local client = NewClient():login()
            local marker = _G.KennelLowHealthMarker
            assert.is_true(marker:IsShown())
            assert.are.same({ "RIGHT", PetFrame, "LEFT", -4, 0 }, { marker:GetPoint() })
            client:petHealth(60)
            assert.are.equal(0, alpha())
            client:petHealth(30)
            assert.are.equal(1, alpha())
        end)

        it("works while the pet's health is hidden, without reading it", function()
            local client = NewClient():login()
            client.healthSecret = true
            client:petHealth(20)
            assert.is_true(issecretvalue(_G.KennelLowHealthMarker.alpha), "handed on as the client gave it")
            assert.are.equal(1, alpha())
            client:petHealth(80)
            assert.are.equal(0, alpha())
        end)

        it("follows the low line, and is gone at 0%", function()
            local client = NewClient():login()
            local args = client.Kennel:GetOptionsTable().args.CareButton.args
            args.low.set({}, 25)
            client:petHealth(30)
            assert.are.equal(0, alpha())
            client:petHealth(20)
            assert.are.equal(1, alpha())
            args.low.set({}, 0)
            assert.is_false(_G.KennelLowHealthMarker:IsShown())
        end)

        it("is gone without a living pet, or with its switch or the module off", function()
            local client = NewClient():login()
            local marker = _G.KennelLowHealthMarker
            client:petDies()
            assert.is_false(marker:IsShown())
            client:petBack()
            assert.is_true(marker:IsShown())
            local args = client.Kennel:GetOptionsTable().args.CareButton.args
            args.marker.set({}, false)
            assert.is_false(marker:IsShown())
            args.marker.set({}, true)
            client.Kennel:SetModuleOn("CareButton", false)
            assert.is_false(marker:IsShown())
        end)

        it("stays away on a client without curves", function()
            NewClient({ noCurveAPI = true }):login():petHealth(10)
            assert.is_false(_G.KennelLowHealthMarker:IsShown())
        end)
    end)

    describe("learning from failed casts", function()
        it("takes a failed Call Pet without a pet for a dead pet", function()
            local client = NewClient({ noPet = true }):login()
            client:castFails(CALL)
            assert.are.equal("Revive Pet", client:press())
            assert.are.equal("Your pet is dead", client:toastTitle())
            assert.are.equal("Call Pet failed: the button casts Revive Pet now.", client:toast().Text.text)
        end)

        it("takes the error 'Your pet is dead' for one as well", function()
            assert.are.equal("Revive Pet", NewClient({ noPet = true }):login():uiError("Your pet is dead."):press())
        end)

        it("leaves other errors, hidden ones, and a pet that exists alone", function()
            local client = NewClient({ noPet = true }):login()
            client:uiError("You are moving."):uiError(SECRET):uiError(nil)
            assert.are.equal("Call Pet", client:press())
            client = NewClient():login():uiError("Your pet is dead.")
            assert.are.equal("Mend Pet", client:press())
        end)

        it("does not take a failed Call Pet on a mount for a dead pet", function()
            local client = NewClient({ noPet = true }):login()
            client.mounted = true
            client:castFails(CALL)
            assert.are.equal("Call Pet", client:press())
        end)

        it("says to hold Shift in combat, and switches once combat ends", function()
            local client = NewClient({ noPet = true }):login():enterCombat()
            client.Kennel:HideToast()
            client:castFails(CALL)
            assert.are.equal(
                "Call Pet failed. In combat the button cannot switch: hold Shift for Revive Pet.",
                client:toast().Text.text
            )
            assert.are.equal("Call Pet", client:press())
            assert.are.same({}, client.blocked, "it did not try")
            client:leaveCombat()
            assert.are.equal("Revive Pet", client:press())
        end)

        it("does not switch after combat when a living pet came back in it", function()
            local client = NewClient({ noPet = true }):login():enterCombat():castFails(CALL)
            client:petBack():petGone():leaveCombat()
            assert.are.equal("Call Pet", client:press())
        end)

        it("goes back to Call Pet when Revive Pet fails at once: no dead pet", function()
            local client = NewClient({ noPet = true, saved = saved(nil, { petDead = true }) }):login()
            assert.are.equal("Revive Pet", client:press())
            client:castFails(REVIVE)
            assert.are.equal("Call Pet", client:press())
            assert.is_true(client:printedContains("Revive Pet failed, so there is no dead pet"))
        end)

        it("keeps Revive Pet when its cast was interrupted", function()
            local client = NewClient({ noPet = true, saved = saved(nil, { petDead = true }) }):login()
            client:castStarts(REVIVE, "Cast-7"):castFails(REVIVE, "Cast-7")
            assert.are.equal("Revive Pet", client:press())
            client:castStarts(MEND, "Cast-8"):castStarts(REVIVE, SECRET)
        end)

        it("switches nothing on a Revive Pet failing in combat or on a body still there", function()
            local client = NewClient({ noPet = true, saved = saved(nil, { petDead = true }) }):login():enterCombat()
            client:castFails(REVIVE)
            assert.are.equal("Revive Pet", client:press())
            client = NewClient():login():petDies():castFails(REVIVE)
            assert.are.equal("Revive Pet", client:press())
            client = NewClient({ noPet = true }):login():castFails(REVIVE)
            assert.are.equal("Call Pet", client:press())
        end)

        it("leaves hidden cast values, other spells and other units alone", function()
            local client = NewClient({ noPet = true }):login()
            client:castFails(SECRET):castFails(CALL, SECRET):castFails(MEND)
            client:fire("UNIT_SPELLCAST_FAILED", "pet", "Cast-1", CALL)
            assert.are.equal("Call Pet", client:press())
        end)
    end)

    describe("the KennelCare macro", function()
        it("is made for the character the first time, following the button", function()
            local client = NewClient():login()
            assert.are.equal(ALIVE, client:macroBody("KennelCare"))
            assert.are.equal(134400, client:macro("KennelCare").icon)
        end)

        it("shows Revive Pet when made while the pet counts as dead", function()
            local client = NewClient({ noPet = true, saved = saved(nil, { petDead = true }) }):login()
            assert.are.equal(DEAD, client:macroBody("KennelCare"))
        end)

        it("follows the button outside combat", function()
            local client = NewClient():login():petDies()
            assert.are.equal(DEAD, client:macroBody("KennelCare"))
            client:petGone()
            assert.are.equal(DEAD, client:macroBody("KennelCare"), "still Revive Pet once the body is gone")
            client:petBack()
            assert.are.equal(ALIVE, client:macroBody("KennelCare"))
        end)

        it("waits in combat and is written once combat ends", function()
            local client = NewClient():login():enterCombat()
            client:petDies():petGone()
            assert.are.equal(ALIVE, client:macroBody("KennelCare"), "not edited in combat")
            assert.are.same({}, client.blocked, "and not tried")
            client:leaveCombat()
            assert.are.equal(DEAD, client:macroBody("KennelCare"))
        end)

        it("is not edited again when it is right already", function()
            local client = NewClient():login()
            client:fire("UPDATE_MACROS")
            assert.are.equal(0, client.macroEdits)
            client:petDies()
            assert.are.equal(1, client.macroEdits, "its own UPDATE_MACROS changed nothing more")
        end)

        it("is brought up to date when the macros change", function()
            local client = NewClient({ noPet = true, saved = saved(nil, { petDead = true }) }):login()
            client:macro("KennelCare").body = ALIVE
            client:fire("UPDATE_MACROS")
            assert.are.equal(DEAD, client:macroBody("KennelCare"))
        end)

        it("takes an older /cast line for its own and writes it with /use", function()
            local client = NewClient({ noPet = true }):login()
            client:macro("KennelCare").body = "#showtooltip\n" .. ALIVE_CAST:gsub("^/use", "/cast")
            client:fire("UPDATE_MACROS")
            assert.are.equal(ALIVE, client:macroBody("KennelCare"))
        end)

        it("keeps the player's own lines and only rewrites its cast line", function()
            local client = NewClient():login()
            client:macro("KennelCare").body = "#ShowTooltip Old\n/petattack\n" .. ALIVE_CAST .. "\n/say hi"
            client:petDies()
            assert.are.equal("#showtooltip\n/petattack\n" .. DEAD_CAST .. "\n/say hi", client:macroBody("KennelCare"))
        end)

        it("is left alone when its first line is no #showtooltip, or when it is gone", function()
            local client = NewClient():login()
            client:macro("KennelCare").body = ALIVE_CAST
            client:petDies()
            assert.are.equal(ALIVE_CAST, client:macroBody("KennelCare"))
            client = NewClient():login()
            client.charMacros = {}
            client:petDies()
            assert.are.equal(0, client.macroEdits)
        end)

        it("is made again from the settings page", function()
            local client = NewClient():login()
            client.charMacros = {}
            client.Kennel:GetOptionsTable().args.CareButton.args.macro.func()
            assert.are.equal(ALIVE, client:macroBody("KennelCare"))
        end)
    end)

    describe("the settings page", function()
        local client, args

        before_each(function()
            client = NewClient():login()
            args = client.Kennel:GetOptionsTable().args.CareButton.args
        end)

        it("passes AceConfig's validation", function()
            LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(client.Kennel:GetOptionsTable(), "Kennel")
        end)

        it("sets the toasts, the low line and the sound", function()
            for key, value in pairs({ died = false, nopet = false, low = 25, sound = "off" }) do
                args[key].set({}, value)
                assert.are.equal(value, args[key].get(), key)
            end
        end)

        it("takes a low toast away when the line is lowered past it", function()
            client:petHealth(30)
            args.low.set({}, 0)
            client:animate(1)
            assert.is_false(client:toast().shown)
        end)

        it("counts the pet as dead or alive by hand, outside combat", function()
            client:petGone()
            args.dead.func()
            assert.are.equal("Revive Pet", client:press())
            args.alive.func()
            assert.are.equal("Call Pet", client:press())
            client:enterCombat()
            args.dead.func()
            assert.are.equal("Call Pet", client:press())
            assert.is_true(client:printedContains("Not in combat"))
        end)

        it("shows an example toast", function()
            args.test.func()
            assert.are.equal("Your pet is dead", client:toastTitle())
        end)
    end)

    it("works again after a profile change", function()
        local client = NewClient():login()
        client.Kennel.db:SetProfile("Other")
        assert.are.equal("Mend Pet", client:press())
        assert.are.equal(1, #client.drivers)
    end)
end)
