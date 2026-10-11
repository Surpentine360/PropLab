local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Model, Config = require(Shared.Model), require(Shared.Config)
local Transform = {}
Transform.__index = Transform
local axes = { X = 1, Y = 2, Z = 3 }
local faces = {
    [Enum.NormalId.Right] = { 1, 1 }, [Enum.NormalId.Left] = { 1, -1 },
    [Enum.NormalId.Top] = { 2, 1 }, [Enum.NormalId.Bottom] = { 2, -1 },
    [Enum.NormalId.Back] = { 3, 1 }, [Enum.NormalId.Front] = { 3, -1 },
}
local function rounded(value, step) return math.round(value / step) * step end
function Transform.nudge(part, tool, axis, amount)
    local index = axes[axis]
    if tool == "Move" then
        part.position[index] = math.clamp(part.position[index] + amount, if index == 2 then 0 else -Config.Bounds, if index == 2 then Config.MaxHeight else Config.Bounds)
    elseif tool == "Scale" then part.size[index] = math.clamp(part.size[index] + amount, Config.MinSize, Config.MaxSize)
    elseif tool == "Rotate" then part.rotation[index] = (part.rotation[index] + amount + 180) % 360 - 180 end
end
function Transform.new(gui, scene, state, onPreview, onCommit)
    local self = setmetatable({ state = state, scene = scene, onPreview = onPreview, onCommit = onCommit }, Transform)
    local proxy = Instance.new("Part")
    proxy.Name, proxy.Anchored, proxy.Transparency = "TransformGuide", true, 1
    proxy.CanCollide, proxy.CanQuery, proxy.CanTouch = false, false, false
    proxy.Parent = scene.root
    self.proxy = proxy
    self.handles = Instance.new("Handles")
    self.handles.Color3 = Color3.fromRGB(63, 145, 255)
    self.handles.Parent = gui
    self.arcs = Instance.new("ArcHandles")
    self.arcs.Parent = gui
    local function begin()
        if state.busy or state.modalOpen or state.mode ~= "Build" or not state:part() then return end
        self.original = Model.copy(state:part())
        self.model = Model.copy(state.model)
        self.dragging = true
    end
    self.handles.MouseButton1Down:Connect(begin)
    self.arcs.MouseButton1Down:Connect(begin)
    self.handles.MouseDrag:Connect(function(face, distance)
        if not self.dragging then return end
        local part = Model.find(self.model, state.selected)
        local axis, sign = table.unpack(faces[face])
        local key = if state.tool == "Move" then "position" else "size"
        part[key] = Model.copy(self.original[key])
        local amount = rounded(distance, state:step()) * (if state.tool == "Move" then sign else 1)
        Transform.nudge(part, state.tool, ({ "X", "Y", "Z" })[axis], amount)
        self.changed = self.changed or math.abs(amount) > 0
        onPreview(self.model)
    end)
    self.arcs.MouseDrag:Connect(function(axis, relativeAngle)
        if not self.dragging then return end
        local part = Model.find(self.model, state.selected)
        local angle = math.rad(rounded(math.deg(relativeAngle), state:step()))
        local direction = ({ [Enum.Axis.X] = Vector3.xAxis, [Enum.Axis.Y] = Vector3.yAxis, [Enum.Axis.Z] = Vector3.zAxis })[axis]
        local cf = Model.cframe(self.original) * CFrame.fromAxisAngle(direction, angle)
        local x, y, z = cf:ToOrientation()
        part.rotation = { math.deg(x), math.deg(y), math.deg(z) }
        self.changed = self.changed or math.abs(angle) > 0
        onPreview(self.model)
    end)
    return self
end
function Transform:refresh()
    self.handles.Adornee, self.arcs.Adornee = nil, nil
    local part = self.state:part()
    if not part or self.state.busy or self.state.modalOpen or self.state.mode ~= "Build" then return end
    self.proxy.Size = Vector3.new(table.unpack(part.size))
    self.proxy.CFrame = if self.state.tool == "Move" then CFrame.new(table.unpack(part.position)) else Model.cframe(part)
    if self.state.tool == "Move" or self.state.tool == "Scale" then
        self.handles.Style = if self.state.tool == "Move" then Enum.HandlesStyle.Movement else Enum.HandlesStyle.Resize
        self.handles.Adornee = self.proxy
    elseif self.state.tool == "Rotate" then self.arcs.Adornee = self.proxy end
end
function Transform:finish(cancel)
    if not self.dragging then return end
    local model, changed = self.model, self.changed
    self.dragging, self.changed, self.model = false, false, nil
    if changed and not cancel then self.onCommit(model) else self.onPreview(self.state.model) end
end
return Transform
