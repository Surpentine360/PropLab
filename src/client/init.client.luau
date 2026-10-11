local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config, Model = require(Shared.Config), require(Shared.Model)
local EditorState, Scene = require(script.EditorState), require(script.Scene)
local Camera, UI = require(script.Camera), require(script.UI)
local Transform, Input = require(script.Transform), require(script.Input)
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)
local state, scene, camera = EditorState.new(), Scene.new(), Camera.new()
local ui, transform, action, send
local remote = ReplicatedStorage:WaitForChild("PropLabSession", 15)
local function render()
    scene:render(state.model, if state.mode == "Build" then state.selected else nil)
    ui:render()
    transform:refresh()
end
send = function(command, data)
    if state.busy then ui:toast("Finishing your last edit…"); return end
    if not remote then ui:toast("Server unavailable. Stop and use Play in Studio."); return end
    state.busy = true
    transform:refresh()
    local request = data or {}
    request.action, request.revision = command, state.revision
    task.spawn(function()
        local success, response = pcall(function() return remote:InvokeServer(request) end)
        state.busy = false
        if not success or type(response) ~= "table" then
            render(); ui:toast("Connection interrupted. Try your action again."); return
        end
        local oldMode = state.mode
        if response.state then state:apply(response.state) end
        camera.preview = state.mode == "Preview"
        if oldMode ~= state.mode or command == "Load" then camera:focus(state.model) end
        render()
        if response.message then ui:toast(response.message) end
    end)
end
local function edit(mutator)
    if state.busy or state.mode ~= "Build" then return end
    local model = Model.copy(state.model)
    if mutator(model) == false then return end
    local clean, err = Model.validate(model)
    if not clean then ui:toast(err); return end
    send("Edit", { model = clean })
end
action = function(name, value)
    if name == "Zoom" then camera:zoom(value); return end
    if name == "Focus" then camera:focus(state.model, state.selected); return end
    if state.busy then ui:toast("Finishing your last edit…"); return end
    if transform and transform.dragging then return end
    if name == "Resume" then send("Resume"); return end
    if name == "New" then
        ui:confirm("Start a new idea?", "Your current workspace will be cleared. Session saves stay in your library. You can undo the clear.", function() send("New") end)
        return
    end
    if state.mode ~= "Build" then return end
    if table.find({ "Select", "Move", "Rotate", "Scale", "Paint" }, name) then
        state.tool = name
        if name == "Paint" then ui.partsOpen = false end
        render()
    elseif name == "Add" then ui:showShapes()
    elseif name == "AddShape" then
        edit(function(model)
            if #model.parts >= Config.MaxParts then ui:toast("40 parts already! Delete a part to make room."); return false end
            local part = Model.newPart(value, HttpService:GenerateGUID(false))
            part.color = state.color
            local selected = state:part()
            if selected then
                part.position = Model.copy(selected.position)
                part.position[1] = math.clamp(part.position[1] + selected.size[1] / 2 + 2, -Config.Bounds, Config.Bounds)
            end
            state.selected = part.id
            table.insert(model.parts, part)
            return true
        end)
    elseif name == "SelectPart" then
        state.selected = value
        local part = state:part()
        if part and state.tool == "Paint" then
            edit(function(model) Model.find(model, value).color = state.color end)
        else
            if part then state.color = part.color end
            render()
        end
    elseif name == "Color" then
        state.color, state.tool = value, "Paint"
        if state:part() then edit(function(model) Model.find(model, state.selected).color = value end) else render() end
    elseif name == "Snap" then state.snap = not state.snap; render()
    elseif name == "Nudge" then
        if not state:part() then return end
        edit(function(model) Transform.nudge(Model.find(model, state.selected), state.tool, value.axis, value.sign * state:step()) end)
    elseif name == "Duplicate" then
        if not state:part() then ui:toast("Select a part first."); return end
        edit(function(model)
            if #model.parts >= Config.MaxParts then ui:toast("Part cap reached: 40 / 40."); return false end
            local part = Model.copy(state:part())
            part.id = HttpService:GenerateGUID(false)
            part.position[1] = math.clamp(part.position[1] + 1, -Config.Bounds, Config.Bounds)
            part.position[3] = math.clamp(part.position[3] + 1, -Config.Bounds, Config.Bounds)
            table.insert(model.parts, part)
            state.selected = part.id
            return true
        end)
    elseif name == "Delete" then
        if not state:part() then ui:toast("Select a part first."); return end
        edit(function(model)
            local _, index = Model.find(model, state.selected)
            table.remove(model.parts, index)
        end)
    elseif name == "Undo" or name == "Redo" or name == "Save" or name == "Submit" then send(name)
    elseif name == "Reset" then
        ui:confirm("Clear your workspace?", "All current parts will be removed. Your session library is kept, and Undo can restore the build.", function() send("Reset") end)
    elseif name == "Back" then
        ui:confirm("Ready for a close-up?", "Finish your Free Build to see your creation on display. You can return to editing afterward.", function() send("Submit") end)
    elseif name == "Library" then ui:showLibrary()
    elseif name == "Load" then
        ui:confirm("Load Model " .. value .. "?", "This replaces your current workspace. You can undo the load to recover your previous build.", function() send("Load", { id = value }) end)
    elseif name == "RemoveSave" then
        ui:confirm("Remove this session save?", "Model " .. value .. " will leave the library. Your current workspace will stay as it is.", function() send("RemoveSave", { id = value }) end)
    end
end
ui = UI.new(state, action)
transform = Transform.new(ui.gui, scene, state, function(model)
    scene:render(model, state.selected)
end, function(model) send("Edit", { model = model }) end)
ui.onModalChanged = function() transform:refresh() end
Input.bind(state, ui, camera, transform, scene, action)
render()
send("Sync")
