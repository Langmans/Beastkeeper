# Toast skins

The toast is an engine and a skin. The engine (`Core\Toast\Engine.lua`) keeps
the queue, the clock (intro, stay, fade; the stay stands still while the mouse
is over the toast), the sound and the settings. A skin draws: Kennel brings
`card` and `splash` (`Core\Toast\Skins\`), and another addon can register its own,
either to draw in its own style (an ElvUI look, say) or as an adapter that
hands the toast to something else.

A skin is a table with a localized `name` and four methods
(`KennelToastSkin` in `annotations\Kennel.lua`). The engine calls `Show` once,
`Update` every frame until the fade is done, then `Hide`:

```lua
local Kennel = LibStub("AceAddon-3.0"):GetAddon("Kennel", true)
if Kennel then
    -- A skin drawing in one frame (self.frame): Hide, IsMouseOver and Frame come with it.
    local skin = Kennel:NewToastSkin("My look")
    function skin:Show(info, settings)
        -- info: key, type, source, title, text, hint, icon, accent, portrait; settings: scale, pos, ...
        self.frame = self.frame or Kennel:NewToastFrame("MyAddonToast") -- drags and closes like Kennel's
        -- fill in self.frame from info
        Kennel:PlaceToast(self.frame, "TOP", 0, -150) -- or where the player dragged the toast
        self.frame:Show()
        -- For info.portrait: Kennel:AddToastPortrait(frame, icon, size) once when building,
        -- then Kennel:ShowToastPortrait(frame, info.portrait, accent) here.
    end
    function skin:Update(intro, fade, left) -- each 0 to 1
        self.frame:SetAlpha(intro * (1 - fade))
    end
    Kennel:RegisterToastSkin("mylook", skin)
end
```

An adapter that hands toasts to something else sets `instant = true` and
needs only `name` and `Show`: the engine plays the sound and moves on to the
next toast at once. A skin with settings of its own adds `GetOptions()`,
returning an AceConfig group that appears in the toast box under its id.
`Integrations\LibSink\Toast.lua` is such an adapter: it pours the toast as one
line through LibSink, where the player picks the output (Blizzard's floating
text by default, chat, raid warning, MikSBT, ...).

To restyle the card or the splash rather than draw anew,
`Kennel:NewCardSkin(name, style)` and `Kennel:NewSplashSkin(name, style)` take
a `KennelSkinStyle`: the frame's name, a panel colour, an edge colour or a
`Border(frame)` function, an `accent()` function and a `Font(text, size)`
function. `Integrations\EllesmereUI\Look.lua` does exactly that with
EllesmereUI's font, border, panel and theme colour, registering "EllesmereUI"
and "EllesmereUI (splash)" only when EllesmereUI is loaded;
`Integrations\ElvUI\Look.lua` the same for ElvUI, its backdrop as the panel.

The player then picks "My look" on Kennel's page. A saved choice whose skin
is gone (its addon disabled) falls back to the card.

The contract is enforced in the game, not only in the editor types:
`RegisterToastSkin` raises an error naming what is missing (an id, a `name`
string, or one of the four methods) and does not register the skin. When a
registered skin errors while it draws, the error goes to the error handler
(BugSack shows it) and the card takes over that toast, so a broken skin
cannot stop Kennel's toasts. An error in `Hide` only lets the toast go.

To change a toast rather than draw it, listen to `KENNEL_TOAST`
([04-hooking.md](04-hooking.md)).
