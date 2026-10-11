local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Model = require(Shared.Model)
local EditorState = {}
EditorState.__index = EditorState
function EditorState.new()
    return setmetatable({ model = { version = 1, parts = {} }, revision = 0, library = {},
        selected = nil, tool = "Select", snap = true, mode = "Build", busy = false,
        canUndo = false, canRedo = false, prompt = "Make a tiny robot", color = 1 }, EditorState)
end
function EditorState:apply(snapshot)
    for key, value in pairs(snapshot) do self[key] = value end
    if self.selected and not Model.find(self.model, self.selected) then self.selected = nil end
end
function EditorState:part() return Model.find(self.model, self.selected) end
function EditorState:step()
    if self.tool == "Rotate" then return if self.snap then 15 else 1 end
    return if self.snap then 1 else 0.25
end
return EditorState
