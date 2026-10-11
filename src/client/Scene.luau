local Lighting = game:GetService("Lighting")
local Shapes = require(script.Parent.Shapes)
local Scene = {}
Scene.__index = Scene
local function block(parent, name, size, position, color)
    local part = Instance.new("Part")
    part.Name, part.Size, part.Position, part.Color = name, size, position, color
    part.Anchored, part.CanCollide, part.CanQuery = true, false, false
    part.Material = Enum.Material.SmoothPlastic
    part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end
function Scene.new()
    local self = setmetatable({ instances = {} }, Scene)
    local root = Instance.new("Folder")
    root.Name, root.Parent = "PrivateWorkshop", workspace
    self.root = root
    self.parts = Instance.new("Folder")
    self.parts.Name, self.parts.Parent = "YourProp", root
    Lighting.ClockTime, Lighting.Brightness = 14, 2
    Lighting.Ambient = Color3.fromRGB(137, 149, 183)
    Lighting.OutdoorAmbient = Color3.fromRGB(172, 188, 215)
    block(root, "Workshop floor", Vector3.new(220, 1, 220), Vector3.new(0, -2, 0), Color3.fromRGB(165, 186, 211))
    block(root, "Build platform", Vector3.new(66, 1.2, 66), Vector3.new(0, -0.65, 0), Color3.fromRGB(225, 233, 245))
    for n = -32, 32, 4 do
        block(root, "Grid", Vector3.new(64, 0.012, 0.035), Vector3.new(0, -0.04, n), Color3.fromRGB(197, 211, 231))
        block(root, "Grid", Vector3.new(0.035, 0.012, 64), Vector3.new(n, -0.04, 0), Color3.fromRGB(197, 211, 231))
    end
    for _, z in ipairs({ -33, 33 }) do
        block(root, "Blue edge", Vector3.new(66, 0.16, 0.2), Vector3.new(0, 0, z), Color3.fromRGB(105, 152, 255))
    end
    block(root, "Back wall", Vector3.new(140, 34, 2), Vector3.new(0, 15, -65), Color3.fromRGB(219, 229, 243))
    for _, x in ipairs({ -49, 49 }) do
        block(root, "Workshop plinth", Vector3.new(15, 5, 12), Vector3.new(x, 0.5, -42), Color3.fromRGB(189, 204, 227))
        block(root, "Accent", Vector3.new(15.2, 0.4, 12.2), Vector3.new(x, 3.2, -42), Color3.fromRGB(111, 145, 233))
    end
    local selection = Instance.new("SelectionBox")
    selection.Name, selection.LineThickness = "Selection", 0.035
    selection.Color3 = Color3.fromRGB(50, 116, 255)
    selection.SurfaceColor3, selection.SurfaceTransparency = selection.Color3, 0.94
    selection.Parent = root
    self.selection = selection
    return self
end
function Scene:render(model, selected)
    local present = {}
    for _, data in ipairs(model.parts) do
        local part = self.instances[data.id]
        if not part then part = Shapes.create(data); part.Parent = self.parts; self.instances[data.id] = part end
        Shapes.update(part, data)
        present[data.id] = true
    end
    for id, part in pairs(self.instances) do
        if not present[id] then part:Destroy(); self.instances[id] = nil end
    end
    self.selection.Adornee = self.instances[selected]
end
function Scene:pick(position)
    local ray = workspace.CurrentCamera:ScreenPointToRay(position.X, position.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { self.parts }
    local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    return if result then result.Instance:GetAttribute("PartId") else nil
end
return Scene
