# #scripter-hiring: Scripter (Luau)

**Status:** ready to post; see the note at the bottom first.

## The post

Paste this into **#scripter-hiring** and attach the images below.

```
**[FOR HIRE] Scripter: Luau Modules for Combat, VFX, UI and Audio**
Typed (`--!strict`) Luau ModuleScripts that a team can call in one line and read later.

**Shown in my portfolio:** an ability VFX system (6 layered abilities), a UI kit used to build 5 game screens, an audio module with mixing buses and round-robin sounds
**I write:** client/server split with RemoteEvents, cleanup with Debris, no leaked instances
**Delivery:** ModuleScripts in your place or as files, with usage notes at the top

**Payment:** Robux or USD (PayPal) · per task or per project · DM for rates
**Contact:** ktfp  ·  **Roblox:** BizarreWasTaken (https://www.roblox.com/users/profile?username=BizarreWasTaken)  ·  **Portfolio:** [dawmo1.github.io](https://dawmo1.github.io)
```

## Images to attach

<img src="../../review/studio/vfx_lightning.jpg" alt="ActionVFX.LightningStrike in Studio" width="49%"> <img src="../../review/studio/ui_eggshop.jpg" alt="Screen built with UIKit" width="49%">

| File | What it shows |
|---|---|
| [`review/studio/vfx_lightning.jpg`](../../review/studio/vfx_lightning.jpg) | ActionVFX.LightningStrike in Studio |
| [`review/studio/ui_eggshop.jpg`](../../review/studio/ui_eggshop.jpg) | Screen built with UIKit |

## What's behind it

- `vfx/roblox/ActionVFX.lua` (365 lines): abilities, emitter builder, camera shake, debris, light flashes
- `ui/roblox/UIKit.lua` (140 lines), `sfx/SFXPresets.lua` (123 lines), `vfx/VFXPresets.lua` (173 lines)

> **Before posting:** Not shown yet: game systems such as DataStore saving, server-checked remotes, or a round/match loop. Most scripter posts ask for these; build one before posting here.
