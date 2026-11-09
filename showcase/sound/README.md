# Sound: 28 original sounds and a mixer

Every sound is synthesised from scratch (no library audio), 48 files counting variations, mastered to WAV, then mixed to game level and exported as OGG.

Play them all in a browser: [`showcase/vfx-sfx.html`](../vfx-sfx.html).

## Use it

```lua
local SFX = require(path.to.SFXPresets)
SFX.play("ui_click")                    -- 2D, for UI
SFX.playAt("sword_hit", hitPosition)     -- 3D, picks a random variation
local engine = SFX.loop("kart_engine_loop", kart.PrimaryPart)
engine.PlaybackSpeed = 0.8 + speed / 60  -- rev with the kart's speed
```

## Source

- [`sfx/SFXPresets.lua`](../../sfx/SFXPresets.lua) (123 lines): routes every sound through SoundGroup buses (UI, SFX, Vehicle, Ambience) so a settings menu only needs four sliders
- [`sfx/mix.txt`](../../sfx/mix.txt): the level each sound is mixed to
- [`sfx/wav/`](../../sfx/wav/): the masters; [`sfx/ogg/`](../../sfx/ogg/): the game-ready exports
- [`tools/make_sfx.py`](../../tools/make_sfx.py) and [`tools/make_sfx_action.py`](../../tools/make_sfx_action.py): the synthesis scripts, so any sound can be re-tuned and re-rendered
