# Button skins

Kennel's buttons (Feeding's feed button) and what holds buttons (its food
list) take their look from a skin, registered like a toast skin
(`Core\Buttons.lua`). Kennel brings its own, `kennel`; the integrations add
EllesmereUI's, ElvUI's and Masque's when those are loaded. On Kennel's page,
"Buttons" has a choice for each: a skin, or Automatic, which takes the
registered skin with the highest `priority`: Masque 30, ElvUI 20, EllesmereUI
10, Kennel 0. A module styles its button the first time it shows it, so a new
choice shows after /reload. A skin that errors is reported and Kennel's own
takes over.

## A button skin

A table with a localized `name`, an optional `priority` and `Style(button,
parts)` (`KennelButtonSkin` in `annotations\Kennel.lua`). `parts.icon` is the
button's icon texture, `parts.group` the module ("Feeding"). `Style` runs
once; it returns a function that colours the border (the feed button shows
the pet's happiness with it), or nil when the look has no border to colour.

```lua
local Kennel = LibStub("AceAddon-3.0"):GetAddon("Kennel", true)
if Kennel then
    Kennel:RegisterButtonSkin("mylook", {
        name = "My look",
        priority = 15,
        Style = function(button, parts)
            parts.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            local border = button:CreateTexture(nil, "OVERLAY")
            -- draw the border
            return function(r, g, b)
                border:SetVertexColor(r, g, b)
            end
        end,
    })
end
```

## A holder skin

What holds buttons: `name`, `priority`, `Style(frame)` for the panel (run
once; the frame is made with `BackdropTemplate`), `Font(text, size)` for a
row's text, and optionally `CropIcon(icon)` for a row's icon, `Accent()` for
the colour that marks what is chosen (the window's tab, the chosen row; the
game's gold without it), `CropsIcons()` when the UI has its own setting for
cropping icons (Kennel's switch then follows it, greyed; ElvUI's Crop Icons)
and `Close(button)` for a close button
(`KennelButtonHolderSkin`). ElvUI's adds Eltruism's shadow to a panel when
Eltruism is loaded with its shadows on. Register it with
`Kennel:RegisterButtonHolderSkin(id, skin)`. Masque skins buttons only, so it
has no holder skin; with Masque the list takes the next one.

## For a module

`Kennel:StyleButton(button, { icon = icon, group = "MyModule" })` styles a
button with the chosen skin and gives the colouring function;
`Kennel:StyleButtonHolder(frame)` styles a panel and gives the holder skin
used, for its `Font` on the rows; `Kennel:CropIcon(icon, skin.CropIcon)` trims
an icon, or leaves it whole when the switch "Crop icons of their border" is
off (an icon pack without borders, such as Clean Icons). Call them when the button is
first shown, not at load: the choice lives in the saved settings.
