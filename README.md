# Something

This repository contains the MegaPanel client script and a Rojo project definition.

## Project layout

- `Script.lua` is the client script source.
- `default.project.json` maps that source to **StarterPlayer > StarterPlayerScripts > Main** and explicitly creates it as a **LocalScript**.

This matters because the script uses `Players.LocalPlayer` and `PlayerGui`. It must run on the client. A plain `.lua` file is normally treated as a ModuleScript by Rojo, so the project file explicitly sets its class to `LocalScript`.

## Open in Roblox Studio with Rojo

1. Open this repository folder on your computer.
2. Run `rojo serve` from that folder.
3. In Roblox Studio, open the Rojo plugin and connect to the local server.
4. Press **Play** to test the client script.

You can also build a place file with `rojo build -o Something.rbxlx`, then open `Something.rbxlx` in Studio.

## Without Rojo

Create a **LocalScript** under **StarterPlayer > StarterPlayerScripts** in Roblox Studio and paste the contents of `Script.lua` into it. Do not insert it as a normal server Script or as a ModuleScript.

## Scope

This repository is a script project, not a complete game map/place. It does not include a custom Workspace, map, or test arena. The Aim Lab test feature is guarded by `RunService:IsStudio()` and is intended for Studio testing only.
