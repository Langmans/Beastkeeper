# Changelog

## Unreleased

- The framework: a settings page under AddOns → Kennel with a switch per
  module, a page per module with options, and profiles.
- `/kennel` opens the settings page; `/kennel help` lists the module
  commands.
- A toast for every module, in two looks: a small card near the top of the
  screen, or a large splash in the middle. Both have a timer bar; drag to
  move, right-click to close, hover to keep it up. Duration, size and look on
  Kennel's page, and a look per kind of toast. Other addons can add looks.
- Care Button (from Pet Care Button): one key and the KennelCare macro for
  Mend Pet, Revive Pet and Call Pet that remember a dead pet, also once the
  body is gone; toasts when the pet dies, is missing at the pull or runs low.
- With EllesmereUI loaded: the card and the splash in EllesmereUI's look.
- A look that sends toasts through LibSink: Blizzard's floating text, chat,
  raid warning, MikSBT and the other outputs LibSink knows.
- With MessageQueue loaded: a LibSink output that says toasts in a chat
  channel (say, party, group, a custom channel); say, yell and channels go out
  on your next key press or click, as WoW: Forever requires.
- Ability Learned (from Pet Ability Learned): a toast, on the splash by
  default, when your hunter learns a pet ability from a tamed beast, with the
  pet's portrait and free training points; a history per character; hints on
  what a summoned pet can still teach, from what Beast Training shows; a toast
  when your pet gains training points, naming the level-up or loyalty level
  behind them, and one when its loyalty drops; a sound choice for each.
- A kind of toast can start on a look its module picks; the pet's portrait on
  the icon; an optional screenshot per toast.
- Feed Emotes (from Feed Pet Emotes, which it replaces): a random /emote
  every time you feed your pet, with your own lines, conditions and the pet's
  sex per pet. Off until switched on.
- Autocast Check (from Pet Autocast Check): a toast when Growl or Cower
  autocast does not fit solo, dungeon, kite or tank mode; kite and tank mode by
  command, key binding or the KennelKite, KennelKiteOff and KennelTank macros.
