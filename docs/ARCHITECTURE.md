# PROP LAB V1 architecture

Rojo's generated project layout is preserved. `default.project.json` maps `src/shared` to ReplicatedStorage.Shared, `src/server` to ServerScriptService.Server, and `src/client` to StarterPlayerScripts.Client. Modules beside an init script become children of that script.

| File | Responsibility |
| --- | --- |
| shared/Config | Limits, stable palette ordering, shapes, build prompts |
| shared/Model | Versioned serialized model, validation, copying, ID lookup, CFrame conversion |
| server/Session | Authoritative model, revision, bounded undo/redo, private session library, game-mode transitions |
| server/init | Remote transport, per-player sessions, token-bucket request limits, cleanup |
| client/EditorState | Received model and flow state; local tool, selection, palette, snap settings |
| client/Shapes | Primitive instance creation and rendering serialized properties |
| client/Scene | Private workshop, part reconciliation, selection outline and raycasting |
| client/Transform | Drag transactions and bounded axis nudges |
| client/Camera | Scriptable orbit/pan/zoom/focus and slow preview orbit |
| client/UI | Rounded panels, tool rail, parts list, palette, dialogs, library, responsive layout |
| client/Input | Mouse/touch/keyboard routing, UI exclusion, drag completion/cancellation |
| client/init | Editor actions, server requests, state reconciliation, flow presentation |

## Authoritative data and private rendering

The server owns each player's serializable build. Anchored visual parts exist only on that player's client; there is no shared physical model or gameplay collision in V1. A locally altered client can change its own view but cannot submit arbitrary instances or mutate another player's session. A future competitive mode must generate its submitted/physical prop from the server's validated model.

Each committed edit submits a complete bounded model (at most 40 parts), with a revision number. The server validates it and returns a fresh snapshot. Dragging previews locally and commits once on release. Only one client request is in flight; stale revisions are rejected and resynchronized. Request limiting allows an initial burst of 12 and replenishes 8 requests per second per player.

The model intentionally uses plain data:

```lua
{
    version = 1,
    parts = {
        {
            id = "UUID", shape = "Cube",
            position = { 0, 2, 0 }, -- world studs
            size = { 4, 4, 4 }, -- local dimensions
            rotation = { 0, 0, 0 }, -- degree parameters for CFrame.fromOrientation
            color = 1, -- stable Config.Palette index
        },
    },
}
```

Allowed shapes: Cube, Cylinder, Sphere, Wedge. Sizes: 0.5–16 per axis. Centers: X/Z ±24, Y 0–32. Rotations: finite values within ±360 degrees. IDs must be unique strings of 1–48 characters. Unknown fields are stripped; NaN, infinity, malformed vectors, sparse arrays, invalid colors, unsupported versions, and over-cap payloads are rejected. Bounds constrain **centers**, so large or rotated parts may extend past the nominal center bounds or intersect the floor. This is not a mesh containment validator.

Palette indices must remain stable in later versions; append colors rather than reorder them. Future persistent saves should wrap this payload in owner/title/timestamps/thumbnail/mode metadata and migrate by version. Do not persist arbitrary Instances or trust client transforms without repeating validation.

## Game flow and limits

`Build → Submit → Preview → Resume → Build`, or `Preview → New → Build` with the next optional prompt. Prompts are inspiration, not scored objectives. There is no timer, lobby, matchmaking, voting, persistence, or Prop Hunt behavior.

The server keeps up to 60 undo snapshots and 8 saved models per player. Library entries hold independent model copies. Reset, load, and new build are undoable. Save removal is confirmed and not undoable. Session data is released when the player leaves. Finishing does not automatically save; the result screen states that a session copy is saved from the editor.

## Phase 2 recommendation

First complete the Studio checklist and measure first-use build time. Refine handle feedback, camera framing, mobile control sizes, and selection before adding new modeling features. Then add model naming/thumbnails, persistent saves with migrations and failure handling, and server-generated submitted previews. Once building is enjoyable, prototype one multiplayer mode around the existing serialized model and server validation.
