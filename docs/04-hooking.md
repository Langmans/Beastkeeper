# Hooking into Kennel

Kennel tells other addons what it does through
[AceEvent-3.0](https://www.wowace.com/projects/ace3/pages/api/ace-event-3-0)
messages. Any addon can listen; Kennel does not have to know about it.

## How to listen

Register for a message with AceEvent-3.0, from an Ace3 addon or from a plain
table that embeds it. The handler gets the message name and **one table**
with the details. Messages are sent at once (synchronously): your handler runs
before Kennel goes on, so for `KENNEL_TOAST` it can still change the toast.

Kennel loads Ace3 itself, so `LibStub("AceEvent-3.0")` is there once Kennel
has loaded; put `## OptionalDeps: Kennel` in your `.toc` so Kennel loads
first.

## Types

Each message's table is a data transfer object with a fixed shape.
[KennelMessages.lua](KennelMessages.lua), next to this file, describes them
for the Lua language server (LuaLS, or the WoW Lua LS): `KennelToastEvent`,
`KennelPrintEvent`, `KennelRanksKnownEvent`, and `KennelToastInfo` for the
toast. It ships with Kennel and is never loaded in game. Point your
workspace at it, for example in `.luarc.json`:

```json
{ "workspace.library": ["../Kennel/docs"] }
```

Then annotate a handler (`---@param event KennelToastEvent`) and the editor
knows every field.

## The messages

Every table has `module`: the Kennel module it comes from (its internal name,
such as `"AbilityLearned"`), or `nil` for Kennel's core. Fields may be added
later; the ones listed here keep their name and meaning.

### `KENNEL_TOAST`

A toast is about to show, or to wait for the one that is up.

| Field | Type | |
|---|---|---|
| `module` | string? | the part of the toast's key before the colon |
| `toast` | table | Kennel's own toast: `key`, `type` (`"<Module>:<kind>"`), `source`, `title`, `text`, `hint`, `icon`, `accent`, `sound`, `portrait`, `screenshot`. Change it and the toast shows the change. |

### `KENNEL_PRINT`

Kennel printed a line in chat.

| Field | Type | |
|---|---|---|
| `module` | string? | the module that said it; `nil` for the core |
| `line` | string | the line as printed, without Kennel's chat prefix |

### `KENNEL_RANKS_KNOWN`

Ability Learned learned of pet ability ranks the hunter knows that it did not
know before. Sent once per learn, and once per opening of the Beast Training
window with everything new in it.

| Field | Type | |
|---|---|---|
| `module` | string | `"AbilityLearned"` |
| `source` | string | `"learn"` (a learn it saw) or `"training"` (the Beast Training window) |
| `ranks` | table | a list of `{ name = "Claw", rank = 2 }`; the name is in the client's language |

## Example

A small addon that keeps a log of the ranks the hunter learns, says them in
party chat, and puts a mark on every Kennel toast about a dead pet.

`KennelHook.toc`:

```
## Interface: 16001
## Title: Kennel Hook
## OptionalDeps: Kennel
## SavedVariables: KennelHookLog

KennelHook.lua
```

`KennelHook.lua`:

```lua
local AceEvent = LibStub and LibStub("AceEvent-3.0", true)
if not AceEvent then return end -- Kennel (and its Ace3) is not loaded

local hook = AceEvent:Embed({})
KennelHookLog = KennelHookLog or {}

-- Ranks the hunter now knows: keep them, and tell the group about a new learn.
---@param event KennelRanksKnownEvent
hook:RegisterMessage("KENNEL_RANKS_KNOWN", function(_, event)
    for _, known in ipairs(event.ranks) do
        table.insert(KennelHookLog, ("%s %s rank %d"):format(date("%Y-%m-%d"), known.name, known.rank))
        if event.source == "learn" and IsInGroup() then
            SendChatMessage(("learned %s rank %d"):format(known.name, known.rank), "PARTY")
        end
    end
end)

-- Every toast passes here before it shows: mark Care Button's dead-pet toast.
---@param event KennelToastEvent
hook:RegisterMessage("KENNEL_TOAST", function(_, event)
    if event.toast.type == "CareButton:dead" then
        event.toast.title = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t " .. event.toast.title
    end
end)

-- What Kennel says in chat, by module.
---@param event KennelPrintEvent
hook:RegisterMessage("KENNEL_PRINT", function(_, event)
    if event.module == "AutocastCheck" then
        print("Kennel's autocast choice changed: " .. event.line)
    end
end)
```

Stop listening with `hook:UnregisterMessage("KENNEL_TOAST")`, or all at once
with `hook:UnregisterAllMessages()`.
