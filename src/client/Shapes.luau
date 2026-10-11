local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Model = require(Shared.Model)
local Shapes = {}
function Shapes.create(data)
    local part = Instance.new(if data.shape == "Wedge" then "WedgePart" else "Part")
    if data.shape == "Sphere" then part.Shape = Enum.PartType.Ball
    elseif data.shape == "Cylinder" then part.Shape = Enum.PartType.Cylinder end
    part.Name = data.shape
    part.Anchored, part.CanCollide, part.CanTouch = true, false, false
    part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    part.Material = Enum.Material.SmoothPlastic
    part:SetAttribute("PartId", data.id)
    Shapes.update(part, data)
    return part
end
function Shapes.update(part, data)
    part.Size = Vector3.new(table.unpack(data.size))
    part.CFrame = Model.cframe(data)
    part.Color = Color3.fromRGB(table.unpack(Config.Palette[data.color]))
end
return Shapes
