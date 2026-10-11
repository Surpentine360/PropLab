-- Run through scripts/test.py; exercises the actual shared/server modules without Roblox services.
local checks = 0
local function check(condition, message)
    assert(condition, message)
    checks += 1
end
local function call(session, action, fields)
    local request = fields or {}
    request.action, request.revision = action, session.revision
    return session:dispatch(request)
end
local function build(count)
    local model = { version = 1, parts = {} }
    for i = 1, count do model.parts[i] = Model.newPart(Config.Shapes[(i - 1) % 4 + 1], tostring(i)) end
    return model
end
local session = Session.new()
check(call(session, "Sync"), "sync")
check(call(session, "Submit") == false, "empty submission blocked")
check(call(session, "Save") == false, "empty save blocked")
check(call(session, "Edit", { model = build(4) }), "all four shapes accepted")
check(#session.model.parts == 4, "four parts stored")
local changed = Model.copy(session.model)
changed.parts[1].position = { 5, 6, -7 }
changed.parts[1].rotation = { 15, 90, -45 }
changed.parts[1].size = { 1, 8, 0.5 }
changed.parts[1].color = 8
check(call(session, "Edit", { model = changed }), "transform and paint")
check(call(session, "Undo") and session.model.parts[1].color == 1, "undo transform and paint")
check(call(session, "Redo") and session.model.parts[1].color == 8, "redo transform and paint")
check(call(session, "Save"), "session save")
check(call(session, "Reset") and #session.model.parts == 0, "reset")
check(call(session, "Undo") and #session.model.parts == 4, "undo reset")
check(call(session, "Reset"), "reset again")
check(call(session, "Load", { id = 1 }) and session.model.parts[1].color == 8, "load saved model")
session.model.parts[1].color = 2
check(session.library[1].model.parts[1].color == 8, "loaded model does not alias library")
local snapshot = session:snapshot()
snapshot.model.parts[1].color = 3
check(session.model.parts[1].color == 2, "snapshot does not alias live model")
check(call(session, "Edit", { model = build(40) }), "40-part boundary accepted")
local before = session.revision
check(not call(session, "Edit", { model = build(41) }), "41st part rejected")
check(session.revision == before and #session.model.parts == 40, "failed edits leave state unchanged")
check(not session:dispatch({ action = "Reset", revision = before - 1 }), "stale revision blocked")
local mutations = {
    function(m) m.version = 2 end,
    function(m) m.parts[1].shape = "MeshPart" end,
    function(m) m.parts[1].size[1] = 0 end,
    function(m) m.parts[1].size[1] = 17 end,
    function(m) m.parts[1].position[1] = 25 end,
    function(m) m.parts[1].position[2] = -1 end,
    function(m) m.parts[1].position[2] = 33 end,
    function(m) m.parts[1].position[3] = -25 end,
    function(m) m.parts[1].rotation[2] = math.huge end,
    function(m) m.parts[1].rotation[2] = 361 end,
    function(m) m.parts[1].size[1] = 0/0 end,
    function(m) m.parts[1].color = 99 end,
    function(m) m.parts[1].color = 1.5 end,
    function(m) m.parts[1].id = "" end,
    function(m) m.parts[2].id = m.parts[1].id end,
    function(m) m.parts[1].position = "bad" end,
    function(m) m.parts[1].size[4] = 4 end,
    function(m) m.parts.foo = {} end,
    function(m) m.parts[1] = nil end,
    function(m) m.parts[2] = nil; m.parts[5] = Model.newPart("Cube", "5") end,
}
for index, mutate in ipairs(mutations) do
    local invalid = build(4)
    mutate(invalid)
    check(Model.validate(invalid) == nil, "malformed payload " .. index)
end
check(Model.validate(false) == nil, "non-table payload")
check(not session:dispatch("bad"), "non-table request")
check(not call(session, "ArbitraryAction"), "unknown action")
check(not call(session, "Load", { id = {} }), "invalid save ID")
check(call(session, "Submit") and session.mode == "Preview", "submit enters preview")
check(not call(session, "Edit", { model = build(1) }), "preview is read-only")
check(call(session, "Resume") and #session.model.parts == 40, "resume preserves build")
check(call(session, "Submit") and call(session, "New") and #session.model.parts == 0, "new build from preview")
check(session.prompt == 2 and #session.library == 1, "new prompt and library retained")
check(call(session, "Undo") and #session.model.parts == 40, "new build is undoable")
check(call(session, "Edit", { model = build(1) }) and #session.redo == 0, "new edit clears redo")
for _ = 2, Config.MaxSaves do check(call(session, "Save"), "fill library") end
check(not call(session, "Save") and #session.library == Config.MaxSaves, "library capacity")
check(call(session, "RemoveSave", { id = 1 }) and #session.library == Config.MaxSaves - 1, "remove save")
check(call(session, "Save") and session.library[#session.library].id == 9, "save IDs never reused")
for _ = 1, 80 do call(session, "Edit", { model = build(1) }) end
check(#session.undo == Config.MaxHistory, "history bounded")
check(#Session.new().model.parts == 0 and #Session.new().library == 0, "sessions isolated")
print("PASS: " .. checks .. " model/session checks")
