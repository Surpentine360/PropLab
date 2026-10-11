local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Model = require(Shared.Model)
local Session = {}
Session.__index = Session
function Session.new()
    return setmetatable({ model = { version = 1, parts = {} }, undo = {}, redo = {}, library = {},
        mode = "Build", revision = 0, nextSave = 0, prompt = 1 }, Session)
end
function Session:snapshot()
    local library = {}
    for _, entry in ipairs(self.library) do table.insert(library, { id = entry.id, count = #entry.model.parts }) end
    return { model = Model.copy(self.model), mode = self.mode, revision = self.revision,
        canUndo = #self.undo > 0, canRedo = #self.redo > 0, library = library, prompt = Config.Prompts[self.prompt] }
end
function Session:commit(model)
    table.insert(self.undo, Model.copy(self.model))
    if #self.undo > Config.MaxHistory then table.remove(self.undo, 1) end
    self.redo = {}
    self.model = model
end
function Session:dispatch(request)
    if type(request) ~= "table" or type(request.action) ~= "string" then return false, "Invalid request." end
    local action = request.action
    if action == "Sync" then return true end
    if request.revision ~= self.revision then return false, "Editor refreshed. Try that edit again." end
    if self.mode ~= "Build" and action ~= "Resume" and action ~= "New" then return false, "Return to editing first." end
    local message = nil
    if action == "Edit" then
        local clean, err = Model.validate(request.model)
        if not clean then return false, err end
        self:commit(clean)
    elseif action == "Undo" or action == "Redo" then
        local source = if action == "Undo" then self.undo else self.redo
        local destination = if action == "Undo" then self.redo else self.undo
        if #source == 0 then return false, "No edits to " .. string.lower(action) .. "." end
        table.insert(destination, self.model)
        self.model = table.remove(source)
    elseif action == "Save" then
        if #self.model.parts == 0 then return false, "Add a shape before saving." end
        if #self.library >= Config.MaxSaves then return false, "Library full. Remove a saved model to make room." end
        local clean, err = Model.validate(self.model)
        if not clean then return false, err end
        self.nextSave += 1
        table.insert(self.library, { id = self.nextSave, model = clean })
        message = "Model " .. self.nextSave .. " saved for this session."
    elseif action == "Load" or action == "RemoveSave" then
        local index = nil
        for i, entry in ipairs(self.library) do if entry.id == request.id then index = i; break end end
        if not index then return false, "Saved model not found." end
        if action == "Load" then self:commit(Model.copy(self.library[index].model)) else table.remove(self.library, index) end
    elseif action == "Reset" then
        self:commit({ version = 1, parts = {} })
        message = "Workspace cleared. Undo can restore it."
    elseif action == "Submit" then
        if #self.model.parts == 0 then return false, "Build something before finishing." end
        self.mode = "Preview"
    elseif action == "Resume" then self.mode = "Build"
    elseif action == "New" then
        self:commit({ version = 1, parts = {} })
        self.mode = "Build"
        self.prompt = self.prompt % #Config.Prompts + 1
    else return false, "Unknown action." end
    self.revision += 1
    return true, message
end
return Session
