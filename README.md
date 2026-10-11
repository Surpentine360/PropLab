# PROP LAB

A code-first Roblox/Luau V1 prop editor with a Free Build → Finish → Preview loop. Initialized with the existing Rojo 7.7.1 installation and its standard client/server/shared structure.

Build with four primitives, select parts, move/rotate/scale with handles or axis buttons, paint from twelve colors, duplicate/delete, undo/redo, and save/load up to eight models during a session. Includes a 40-part cap, server-side validation, private workshops, snapping, reset confirmation, and a rounded game UI based on the supplied visual direction.

```powershell
Set-Location C:\Projects\PropLab
.\rojo.exe build -o PropLab.rbxlx
.\rojo.exe serve default.project.json
```

Open `PropLab.rbxlx` in Studio, connect the Rojo plugin to `localhost:34872` for live sync, and press **F5 / Play**. The built file also works without a plugin connection. No API-service permissions or DataStore setup are needed.

- [Exact controls, Studio steps, and acceptance checklist](docs/STUDIO_TESTING.md)
- [Architecture, validation rules, limitations, and Phase 2](docs/ARCHITECTURE.md)

Offline: Luau compilation and model/session tests pass; Rojo packages the place. **Studio rendering, handle behavior, touch interaction, and the 60-second usability target are not yet verified.** Run `python scripts/test.py` for repeatable offline checks.

V1 limits: session-only saves, no lobby or avatar, no multiplayer competition, no persistent data, no advanced modeling. Phone portrait asks for landscape; mobile uses axis buttons, with no dedicated touch pan or pinch gestures. A finished preview is not an automatic save.

Git is initialized. Source and docs remain uncommitted for review. Generated place files, the supplied Rojo executable, and downloaded local test tools are ignored.
