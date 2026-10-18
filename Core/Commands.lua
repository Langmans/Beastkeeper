local _, ns = ...

-- The /kennel slash command. Without arguments it opens or closes Kennel's window (Window.lua),
-- "config" opens the options. Otherwise the first word names a module (its `command`) and the
-- second one of that module's `commands`; the rest of the line goes to that command's func.
-- Commands exist for what a macro needs, the window and the options page for everything else.

---@type Kennel
local Kennel = ns
local L = Kennel.L

function Kennel:SetupCommands()
    self:RegisterChatCommand("kennel", "OnSlash")
end

---The module whose `command` is word, if any.
---@param word string
---@return string? name
---@return KennelModule? module
function Kennel:FindCommandModule(word)
    for name, module in pairs(self.modules) do
        if module.command == word then return name, module end
    end
end

---@param input string
function Kennel:OnSlash(input)
    -- GetArgs: the first two words (nil when absent), then where the rest of the line starts.
    ---@type string?, string?, number
    local word, sub, rest = self:GetArgs(input, 2)
    if not word then
        self:ToggleWindow()
    elseif word:lower() == "config" then
        self:OpenOptions()
    elseif word:lower() == "help" then
        self:PrintHelp()
    else
        self:RunModuleCommand(input, word:lower(), sub, rest)
    end
end

---Runs `/kennel <word> <sub> ...`, or says why it cannot.
---@param input string the whole line, for the message when nothing matches
---@param word string the module's command word, lowercase
---@param sub string? the command's name
---@param rest number where the command's arguments start in input
function Kennel:RunModuleCommand(input, word, sub, rest)
    local name, module = self:FindCommandModule(word)
    local command = module and sub and module.commands and module.commands[sub:lower()]
    if not name or not module or not command then
        self:Print(L.UNKNOWN_COMMAND:format(input))
    elseif not self:IsModuleOn(name) then
        self:Print(L.MODULE_OFF:format(module.title or name))
    else
        command.func(module, input:sub(rest))
    end
end

---Lists every module command, sorted, so the order does not depend on table order.
function Kennel:PrintHelp()
    self:Print(L.HELP_HEADER)
    print(L.HELP_WINDOW)
    print(L.HELP_OPTIONS)
    ---@type string[]
    local lines = {}
    for _, module in pairs(self.modules) do
        for sub, command in pairs(module.commands or {}) do
            lines[#lines + 1] = L.HELP_COMMAND:format(module.command, sub, command.desc)
        end
    end
    table.sort(lines)
    for _, line in ipairs(lines) do
        print(line)
    end
end
