local RunService = game:GetService("RunService")
local Camera = {}
Camera.__index = Camera
function Camera.new()
    local self = setmetatable({ yaw = math.rad(35), pitch = math.rad(27), distance = 29, target = Vector3.new(0, 3, 0), preview = false }, Camera)
    RunService:BindToRenderStep("PropLabCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
        local camera = workspace.CurrentCamera
        if not camera then return end
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = 48
        if self.preview then self.yaw += dt * 0.12 end
        local offset = Vector3.new(math.sin(self.yaw) * math.cos(self.pitch), math.sin(self.pitch), math.cos(self.yaw) * math.cos(self.pitch))
        camera.CFrame = CFrame.lookAt(self.target + offset * self.distance, self.target)
        camera.Focus = CFrame.new(self.target)
    end)
    return self
end
function Camera:orbit(delta)
    self.yaw -= delta.X * 0.007
    self.pitch = math.clamp(self.pitch + delta.Y * 0.006, math.rad(8), math.rad(80))
end
function Camera:pan(delta)
    local cf = workspace.CurrentCamera.CFrame
    self.target += (-cf.RightVector * delta.X + cf.UpVector * delta.Y) * self.distance * 0.0016
    self.target = Vector3.new(math.clamp(self.target.X, -24, 24), math.clamp(self.target.Y, 0, 24), math.clamp(self.target.Z, -24, 24))
end
function Camera:zoom(amount) self.distance = math.clamp(self.distance - amount * 2.5, 8, 100) end
function Camera:focus(model, selected)
    local low, high = Vector3.new(24, 32, 24), Vector3.new(-24, 0, -24)
    local count = 0
    for _, part in ipairs(model.parts) do
        if not selected or part.id == selected then
            local pos, radius = Vector3.new(table.unpack(part.position)), Vector3.new(table.unpack(part.size)).Magnitude / 2
            low = low:Min(pos - Vector3.one * radius)
            high = high:Max(pos + Vector3.one * radius)
            count += 1
        end
    end
    if count == 0 then self.target, self.distance = Vector3.new(0, 3, 0), 29; return end
    self.target = (low + high) / 2
    self.distance = math.clamp((high - low).Magnitude * 1.7, 14, 100)
end
return Camera
