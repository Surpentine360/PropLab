local Config = require(script.Parent.Config)
local Model = {}
function Model.copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = Model.copy(item) end
    return result
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function vector(value, low, high)
    if type(value) ~= "table" then return false end
    local count = 0
    for key, component in pairs(value) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 3 then return false end
        if not finite(component) or component < low or component > high then return false end
        count += 1
    end
    return count == 3
end
function Model.validate(payload)
    if type(payload) ~= "table" or payload.version ~= 1 or type(payload.parts) ~= "table" then return nil, "Invalid model format." end
    local count = 0
    for key in pairs(payload.parts) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > Config.MaxParts then return nil, "Invalid parts list." end
        count += 1
    end
    if count > Config.MaxParts or count ~= #payload.parts then return nil, "Part cap reached." end
    for index = 1, count do
        if payload.parts[index] == nil then return nil, "Parts must be a continuous list." end
    end
    local clean, ids = { version = 1, parts = {} }, {}
    for _, part in ipairs(payload.parts) do
        if type(part) ~= "table" or type(part.id) ~= "string" or #part.id > 48 or #part.id < 1 or ids[part.id] then return nil, "Invalid part ID." end
        if not table.find(Config.Shapes, part.shape) then return nil, "Unknown shape." end
        if not vector(part.position, -Config.Bounds, Config.MaxHeight)
            or math.abs(part.position[1]) > Config.Bounds or math.abs(part.position[3]) > Config.Bounds
            or part.position[2] < 0 then return nil, "Keep parts inside the workshop." end
        if not vector(part.size, Config.MinSize, Config.MaxSize) then return nil, "Size must be 0.5–16 studs." end
        if not vector(part.rotation, -360, 360) then return nil, "Invalid rotation." end
        if not finite(part.color) or part.color % 1 ~= 0 or not Config.Palette[part.color] then return nil, "Invalid color." end
        ids[part.id] = true
        table.insert(clean.parts, { id = part.id, shape = part.shape, position = Model.copy(part.position),
            size = Model.copy(part.size), rotation = Model.copy(part.rotation), color = part.color })
    end
    return clean
end
function Model.find(model, id)
    for index, part in ipairs(model.parts) do if part.id == id then return part, index end end
    return nil
end
function Model.newPart(shape, id)
    return { id = id, shape = shape, position = { 0, 2, 0 }, size = { 4, 4, 4 }, rotation = { 0, 0, 0 }, color = 1 }
end
function Model.cframe(part)
    return CFrame.new(table.unpack(part.position)) * CFrame.fromOrientation(
        math.rad(part.rotation[1]), math.rad(part.rotation[2]), math.rad(part.rotation[3]))
end
return Model
