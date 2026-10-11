# PROP LAB V1 — Studio playtest

## Open the exact build

1. In PowerShell, run:
   ```powershell
   Set-Location C:\Projects\PropLab
   .\rojo.exe build -o PropLab.rbxlx
   .\rojo.exe serve default.project.json
   ```
   Leave the serving terminal open. The default Rojo address is `localhost:34872`.
2. In Roblox Studio, stop any existing playtest. Use **File → Open from File** and open `C:\Projects\PropLab\PropLab.rbxlx`. Do not use the unrelated Place1 baseplate.
3. For live sync, open the installed **Rojo** plugin, connect to `localhost:34872`, and accept the sync for this project. If the plugin is missing, the built place can still be tested immediately; install/connect the matching Rojo plugin later for live edits.
4. Open **Output** from Studio's window/view menu so errors remain visible.
5. Use **Play / F5**, not Run. Run alone does not execute the player's editor UI. Expect a pale blue workshop, a gridded platform, PROP LAB header, empty parts list, and a Free Build prompt. There is deliberately no character or lobby.
6. Stop with **Shift+F5** before syncing structural changes. Rebuild/reopen the place if testing without a plugin connection. Source files are the source of truth; do not make unsaved code changes only in Studio.

## Exact controls

| Action | Desktop | Touch / UI |
| --- | --- | --- |
| Add | N, or Add shape | Add shape → Cube / Cylinder / Sphere / Wedge |
| Select | Q, then click a part | Tap a part or its parts-list row |
| Move | W, drag an arrow | X / Y / Z minus and plus buttons |
| Rotate | E, drag a ring | X / Y / Z minus and plus buttons |
| Scale | R, drag a resize handle | X / Y / Z minus and plus buttons |
| Paint | B, then choose a swatch | Paint → swatch; tap other parts to apply it |
| Duplicate | Ctrl+D | Duplicate below the parts list |
| Delete | Delete | Delete below the parts list |
| Undo / redo | Ctrl+Z / Ctrl+Y or Ctrl+Shift+Z | Undo / Redo |
| Save | Ctrl+S, or Save Model | Save Model |
| Load | Library → Load → Continue | Same |
| Orbit | Right mouse drag | Drag empty workshop space |
| Pan | Middle mouse drag | No dedicated touch pan in V1; use Fit |
| Zoom | Mouse wheel | Camera − / + buttons |
| Focus | F | Fit (selected part, or whole build without selection) |
| Cancel | Escape closes dialogs or cancels a drag* | Dialog × / Cancel |
| Reset | Clear build → Continue | Same |
| Finish | Finish, or Back → Continue | Same |

*Roblox may also reserve Escape for its system menu; Cancel and × remain available.

Move controls use world axes. Scale controls change local dimensions symmetrically about the part center. Rings rotate around local axes; rotation buttons increment stored Euler X/Y/Z angles. Roblox cylinders initially point along local X.

Snap ON: move/scale steps of 1 stud, rotation steps of 15°. Fine: 0.25 studs and 1°. The snapping button is also available in the transform panel. The UI calls the second setting **Fine** because it still uses small increments.

Compact layouts collapse the parts panel behind **Parts** and show the palette in Paint mode. The tool rail scrolls when vertical space is limited. Phone portrait displays a landscape instruction. Tablet/desktop layouts are the primary V1 targets; check phone button sizes on real hardware.

## The 60-second usability check

Start a timer after the editor appears:

1. Add a Cube.
2. Select Move, press Y+ once (verify movement).
3. Select Scale, press Y− twice (make a flatter base).
4. Select Paint and choose blue.
5. Add a Sphere; select Paint and choose yellow.
6. Select Move and use X− / Y+ to place the sphere above the base.
7. Save Model. Confirm the toast and the library entry.

This makes a simple desk sculpture. Record completion time, missed taps, misunderstood controls, and any time spent searching for a tool. The under-60-second target has **not** been measured in Studio yet.

## Functional checklist

All boxes below are deliberately unchecked: these are runtime acceptance tests, not claims of completed Studio testing.

- [ ] **Startup:** Play opens the workshop without Output errors, camera falling, avatar spawning, or a leftover default baseplate covering the grid.
- [ ] **Shapes:** Add each of Cube, Cylinder, Sphere, Wedge. Check appearance, count, and list order.
- [ ] **Selection:** Click/tap every shape and its list row. The same part gets a blue outline and highlighted row.
- [ ] **Move:** Drag all six directions; use each axis button; test negative coordinates and limits. The part should not jump on first drag.
- [ ] **Rotate:** Drag all three rings and use each axis button. Check snapping, orientation after reload, and a rotated wedge/cylinder.
- [ ] **Scale:** Drag positive and negative faces. Verify predictable growth/shrinkage, minimum 0.5 and maximum 16 per axis, and no negative size.
- [ ] **Snapping:** Compare coarse and Fine for each transform. Release a drag and verify exactly one undo step for that drag.
- [ ] **Paint:** Choose every swatch; apply it to the selected part; tap a second part while Paint is active. Undo restores the previous color.
- [ ] **Duplicate/delete:** Duplicate an edited part. Check copied shape/size/rotation/color, unique selection, slight offset, and deletion of only the selected part.
- [ ] **Undo/redo:** Exercise add → move → rotate → scale → paint → duplicate → delete; undo and redo the chain. A fresh edit after Undo clears Redo.
- [ ] **Save/load:** Save two different builds, load each, and confirm parts, transforms, and colors. Cancel a load. Undo a load to restore the replaced workspace.
- [ ] **Library limit:** Fill eight slots, check the ninth save is rejected, remove a save with confirmation, then save again.
- [ ] **Part cap:** Reach 40. Add and Duplicate must not create a 41st part. Delete one and add another.
- [ ] **Reset:** Cancel once, then confirm. Check empty list/count/selection; Undo restores the model. Saved entries remain.
- [ ] **Finish:** Empty submission is rejected. Finish a nonempty build; observe the rotating preview and hidden edit tools. Keep editing preserves the build. New build asks for confirmation, clears the workspace, and changes the prompt. Undo can restore it.
- [ ] **UI:** Test hover, selection, scrolling, disabled-looking controls, toast messages, and modal clicks. No edits should occur behind dialogs.
- [ ] **Camera:** Orbit, pan, zoom limits, Fit, and selection while zoomed. Move the cursor outside the window during a drag; return and verify no stuck drag.
- [ ] **Small screens:** Use Studio's Device Emulator for a tablet and a landscape phone. Check all tool-rail items, Parts, palette, axis buttons, save/library/finish, and portrait notice. Test actual touch separately.
- [ ] **Privacy:** Start a Studio server with two players. Each player should have a separate empty build, history, and library. Editing one must not change the other.
- [ ] **Session lifecycle:** Stop/restart Play. The session library intentionally disappears.
- [ ] **Usability:** Run the 60-second trial with a first-time player and record results.

## What was verified offline

- Rojo 7.7.1 initialization and place packaging.
- Every source file compiles using the official Luau 0.742 CLI.
- Model/session tests execute the actual Config, Model, and Session modules with only Roblox service imports substituted. They exercise malformed payload rejection, all allowed shapes, bounds, transforms/color serialization, cap enforcement, undo/redo, save/load copying, capacity, revision rejection, session isolation, and flow transitions.
- These tests do **not** emulate Roblox rendering, input, networking, native handles, font glyphs, or Studio device behavior. Those require the checklist above.

Run the offline suite:

```powershell
python scripts/test.py
.\rojo.exe build -o PropLab.rbxlx
```

The test script expects `luau.exe` and `luau-compile.exe` in `.tools/luau`, or accepts `--luau-dir <directory>`. Local CLI binaries are ignored by Git. Install Luau from its official GitHub releases on another machine.
