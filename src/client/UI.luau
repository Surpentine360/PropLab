local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local UI = {}
UI.__index = UI
local C = {
    ink = Color3.fromRGB(34, 48, 91), muted = Color3.fromRGB(113, 128, 158),
    white = Color3.fromRGB(248, 251, 255), line = Color3.fromRGB(213, 224, 244),
    blue = Color3.fromRGB(45, 111, 255), purple = Color3.fromRGB(111, 78, 247),
    pale = Color3.fromRGB(234, 241, 254), selected = Color3.fromRGB(212, 227, 255),
}
local function node(class, parent, props)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(object, radius)
    node("UICorner", object, { CornerRadius = UDim.new(0, radius or 14) })
end
local function stroke(object, color)
    return node("UIStroke", object, { Color = color or C.line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function label(parent, text, pos, size, textSize, color)
    return node("TextLabel", parent, { BackgroundTransparency = 1, Text = text, Position = pos,
        Size = size, Font = Enum.Font.GothamMedium, TextSize = textSize or 14, TextColor3 = color or C.ink,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true })
end
local function panel(parent, pos, size)
    local shadow = node("Frame", parent, { Name = "SoftShadow", BackgroundColor3 = Color3.fromRGB(55, 76, 125),
        BackgroundTransparency = 0.87, BorderSizePixel = 0, Position = pos + UDim2.fromOffset(0, 5), Size = size })
    round(shadow, 20)
    local frame = node("Frame", parent, { BackgroundColor3 = C.white, BorderSizePixel = 0, Position = pos, Size = size })
    round(frame, 18); stroke(frame)
    node("UIGradient", frame, { Color = ColorSequence.new(C.white, Color3.fromRGB(232, 241, 255)), Rotation = 85 })
    return frame, shadow
end
local function button(parent, text, pos, size, callback, color)
    local b = node("TextButton", parent, { Text = text, Position = pos, Size = size, BackgroundColor3 = color or C.pale,
        BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = if color then Color3.new(1, 1, 1) else C.ink })
    round(b, 12)
    b.Activated:Connect(callback)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.15 }):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play() end)
    return b
end
function UI.new(state, action)
    local self = setmetatable({ state = state, action = action, buttons = {}, rows = {}, swatches = {}, modal = nil, partsOpen = false }, UI)
    local gui = node("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {
        Name = "PropLabUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = false, DisplayOrder = 10,
    })
    self.gui = gui
    local outer = node("Frame", gui, { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
    local root = node("Frame", outer, { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
    self.root = root
    local scale = node("UIScale", root, {})
    local header = panel(root, UDim2.new(0.5, -168, 0, 10), UDim2.fromOffset(336, 58))
    label(header, "◆", UDim2.fromOffset(15, 8), UDim2.fromOffset(38, 40), 32, C.purple)
    local title = label(header, "PROP", UDim2.fromOffset(59, 10), UDim2.fromOffset(74, 36), 25)
    title.Font = Enum.Font.GothamBlack
    title = label(header, "LAB", UDim2.fromOffset(134, 10), UDim2.fromOffset(67, 36), 25, C.blue)
    title.Font = Enum.Font.GothamBlack
    node("Frame", header, { BackgroundColor3 = C.line, BorderSizePixel = 0, Position = UDim2.fromOffset(216, 14), Size = UDim2.fromOffset(1, 30) })
    self.counter = label(header, "0 / 40", UDim2.fromOffset(237, 13), UDim2.fromOffset(85, 30), 19)
    self.prompt = label(root, "FREE BUILD  /  Make a tiny robot", UDim2.new(0.5, -225, 0, 76), UDim2.fromOffset(450, 26), 14)
    self.prompt.TextXAlignment = Enum.TextXAlignment.Center
    self.rail, self.railShadow = panel(root, UDim2.fromOffset(16, 94), UDim2.fromOffset(124, 514))
    local railContent = node("ScrollingFrame", self.rail, { BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.fromOffset(0, 514), ScrollBarThickness = 2 })
    local actions = { { "Back", "‹   Back" }, { "Undo", "↶   Undo" }, { "Redo", "↷   Redo" },
        { "Add", "+   Add shape" }, { "Select", "↖   Select" }, { "Move", "✥   Move" },
        { "Rotate", "↻   Rotate" }, { "Scale", "↗   Scale" }, { "Paint", "●   Paint" } }
    for index, entry in ipairs(actions) do
        self.buttons[entry[1]] = button(railContent, entry[2], UDim2.fromOffset(8, 8 + (index - 1) * 49), UDim2.fromOffset(108, 43), function() action(entry[1]) end)
    end
    button(railContent, "Clear build", UDim2.fromOffset(8, 457), UDim2.fromOffset(108, 42), function() action("Reset") end)
    self.partsPanel, self.partsShadow = panel(root, UDim2.new(1, -280, 0, 104), UDim2.fromOffset(264, 414))
    label(self.partsPanel, "Your parts", UDim2.fromOffset(16, 10), UDim2.fromOffset(170, 36), 20)
    button(self.partsPanel, "+", UDim2.fromOffset(211, 12), UDim2.fromOffset(38, 36), function() action("Add") end, C.blue)
    self.partsList = node("ScrollingFrame", self.partsPanel, { BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 60), Size = UDim2.fromOffset(240, 252), CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.blue })
    node("UIListLayout", self.partsList, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    self.partInfo = label(self.partsPanel, "Select a part to edit", UDim2.fromOffset(16, 320), UDim2.fromOffset(232, 32), 12, C.muted)
    self.duplicate = button(self.partsPanel, "Duplicate", UDim2.fromOffset(12, 362), UDim2.fromOffset(117, 40), function() action("Duplicate") end)
    self.delete = button(self.partsPanel, "Delete", UDim2.fromOffset(135, 362), UDim2.fromOffset(117, 40), function() action("Delete") end)
    self.partsToggle = button(root, "Parts", UDim2.new(1, -98, 0, 20), UDim2.fromOffset(82, 44), function()
        self.partsOpen = not self.partsOpen; self:layout()
    end)
    self.bottom, self.bottomShadow = panel(root, UDim2.new(0.5, -204, 1, -70), UDim2.fromOffset(408, 56))
    button(self.bottom, "Save Model", UDim2.fromOffset(6, 6), UDim2.fromOffset(146, 44), function() action("Save") end, C.purple)
    button(self.bottom, "Library", UDim2.fromOffset(158, 6), UDim2.fromOffset(108, 44), function() action("Library") end)
    button(self.bottom, "Finish  →", UDim2.fromOffset(272, 6), UDim2.fromOffset(130, 44), function() action("Submit") end, C.blue)
    self.palette, self.paletteShadow = panel(root, UDim2.new(1, -280, 1, -136), UDim2.fromOffset(264, 120))
    self.snap = button(self.palette, "Snap  ON", UDim2.fromOffset(10, 8), UDim2.fromOffset(117, 32), function() action("Snap") end)
    label(self.palette, "Paint palette", UDim2.fromOffset(139, 8), UDim2.fromOffset(115, 32), 12, C.muted)
    for i, color in ipairs(Config.Palette) do
        local swatch = button(self.palette, "", UDim2.fromOffset(12 + ((i - 1) % 6) * 41, 48 + math.floor((i - 1) / 6) * 32), UDim2.fromOffset(33, 27), function() action("Color", i) end, Color3.fromRGB(table.unpack(color)))
        round(swatch, 8)
        self.swatches[i] = stroke(swatch, C.line)
    end
    self.transformPanel, self.transformShadow = panel(root, UDim2.new(0.5, -201, 1, -181), UDim2.fromOffset(402, 94))
    self.transformTitle = label(self.transformPanel, "Move · 1 stud", UDim2.fromOffset(14, 5), UDim2.fromOffset(276, 26), 13)
    self.transformSnap = button(self.transformPanel, "Snap ON", UDim2.fromOffset(298, 4), UDim2.fromOffset(92, 29), function() action("Snap") end)
    for i, axis in ipairs({ "X", "Y", "Z" }) do
        local x = 12 + (i - 1) * 130
        local color = ({ Color3.fromRGB(228, 97, 120), Color3.fromRGB(46, 163, 120), Color3.fromRGB(60, 130, 233) })[i]
        button(self.transformPanel, "−", UDim2.fromOffset(x, 39), UDim2.fromOffset(39, 42), function() action("Nudge", { axis = axis, sign = -1 }) end)
        local l = label(self.transformPanel, axis, UDim2.fromOffset(x + 42, 39), UDim2.fromOffset(30, 42), 17, color)
        l.TextXAlignment = Enum.TextXAlignment.Center
        button(self.transformPanel, "+", UDim2.fromOffset(x + 78, 39), UDim2.fromOffset(39, 42), function() action("Nudge", { axis = axis, sign = 1 }) end)
    end
    self.cameraTools, self.cameraShadow = panel(root, UDim2.new(0, 16, 1, -66), UDim2.fromOffset(148, 50))
    button(self.cameraTools, "−", UDim2.fromOffset(5, 5), UDim2.fromOffset(38, 40), function() action("Zoom", -1) end)
    button(self.cameraTools, "+", UDim2.fromOffset(48, 5), UDim2.fromOffset(38, 40), function() action("Zoom", 1) end)
    button(self.cameraTools, "Fit", UDim2.fromOffset(91, 5), UDim2.fromOffset(52, 40), function() action("Focus") end)
    self.empty = label(root, "BIG IDEAS. SIMPLE SHAPES.\n\nStart with + Add shape\nMake a robot, a snack, or something only you could imagine.", UDim2.new(0.5, -165, 0.36, 0), UDim2.fromOffset(330, 146), 17)
    self.empty.TextXAlignment = Enum.TextXAlignment.Center
    self.hint = label(root, "Right drag: orbit   ·   Middle drag: pan   ·   Scroll: zoom   ·   F: focus", UDim2.new(0.5, -245, 1, -213), UDim2.fromOffset(490, 24), 11, C.muted)
    self.hint.TextXAlignment = Enum.TextXAlignment.Center
    self.toastLabel = label(root, "", UDim2.new(0.5, -230, 0, 108), UDim2.fromOffset(460, 40), 14)
    self.toastLabel.BackgroundColor3, self.toastLabel.BackgroundTransparency = C.white, 0.05
    self.toastLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.toastLabel.Visible, self.toastLabel.ZIndex = false, 30
    round(self.toastLabel, 12)
    self.preview, self.previewShadow = panel(root, UDim2.new(0.5, -236, 1, -152), UDim2.fromOffset(472, 134))
    label(self.preview, "LOOK WHAT YOU MADE", UDim2.fromOffset(18, 10), UDim2.fromOffset(436, 30), 20, C.purple).TextXAlignment = Enum.TextXAlignment.Center
    self.previewText = label(self.preview, "Your prop is ready for its close-up.", UDim2.fromOffset(18, 42), UDim2.fromOffset(436, 23), 13, C.muted)
    self.previewText.TextXAlignment = Enum.TextXAlignment.Center
    button(self.preview, "Keep editing", UDim2.fromOffset(14, 78), UDim2.fromOffset(216, 42), function() action("Resume") end, C.blue)
    button(self.preview, "New build", UDim2.fromOffset(240, 78), UDim2.fromOffset(216, 42), function() action("New") end)
    self.outer, self.scale = outer, scale
    self.orientation = node("Frame", outer, { BackgroundColor3 = C.white, Size = UDim2.fromScale(1, 1), ZIndex = 100, Visible = false })
    local notice = label(self.orientation, "PROP LAB\n\nTurn your phone sideways\nfor more room to build.\n\nV1 supports landscape phones,\ntablets, and desktop.", UDim2.new(0.1, 0, 0.25, 0), UDim2.fromScale(0.8, 0.5), 22)
    notice.TextXAlignment = Enum.TextXAlignment.Center
    outer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:layout() end)
    self:layout()
    return self
end
function UI:layout()
    local size = self.outer.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return end
    local scale = math.clamp(size.Y / 780, 0.6, 1)
    self.scale.Scale = scale
    self.root.Size = UDim2.fromOffset(size.X / scale, size.Y / scale)
    self.orientation.Visible = size.X < 600 and size.Y > size.X
    self.compact = size.X / scale < 1120 or size.Y / scale < 720
    self.rail.Size = UDim2.fromOffset(124, math.min(514, size.Y / scale - 184))
    self.railShadow.Size = self.rail.Size
    self.partsToggle.Visible = self.compact and self.state.mode == "Build"
    self.partsPanel.Visible = self.state.mode == "Build" and (not self.compact or self.partsOpen)
    self.partsShadow.Visible = self.partsPanel.Visible
    self.partsPanel.Position = UDim2.new(1, -280, 0, if self.compact then 134 else 104)
    local partsHeight = math.min(414, size.Y / scale - 238)
    self.partsPanel.Size = UDim2.fromOffset(264, partsHeight)
    self.partsShadow.Position = self.partsPanel.Position + UDim2.fromOffset(0, 5)
    self.partsShadow.Size = self.partsPanel.Size
    self.partsList.Size = UDim2.fromOffset(240, partsHeight - 162)
    self.partInfo.Position = UDim2.fromOffset(16, partsHeight - 94)
    self.duplicate.Position = UDim2.fromOffset(12, partsHeight - 52)
    self.delete.Position = UDim2.fromOffset(135, partsHeight - 52)
    self.palette.Position = if self.compact then UDim2.new(1, -280, 0, 134) else UDim2.new(1, -280, 1, -136)
    self.palette.Visible = self.state.mode == "Build" and (not self.compact or (self.state.tool == "Paint" and not self.partsOpen))
    self.paletteShadow.Position = self.palette.Position + UDim2.fromOffset(0, 5)
    self.paletteShadow.Visible = self.palette.Visible
    self.hint.Visible = not self.compact and self.state.mode == "Build"
    self.cameraTools.Visible = not self.compact
    self.cameraShadow.Visible = self.cameraTools.Visible
    -- Touch screens keep dedicated zoom/fit access above the lower action area.
    if self.compact then
        self.cameraTools.Position = UDim2.new(1, -164, 0, 70)
        self.cameraShadow.Position = self.cameraTools.Position + UDim2.fromOffset(0, 5)
        self.cameraTools.Visible, self.cameraShadow.Visible = true, true
    else
        self.cameraTools.Position = UDim2.new(0, 16, 1, -66)
        self.cameraShadow.Position = self.cameraTools.Position + UDim2.fromOffset(0, 5)
    end
end
function UI:render()
    local state = self.state
    self.counter.Text = string.format("%d / %d", #state.model.parts, Config.MaxParts)
    self.prompt.Text = (if state.mode == "Build" then "FREE BUILD  /  " else "BUILD COMPLETE  /  ") .. state.prompt
    self.empty.Visible = #state.model.parts == 0
    for name, b in pairs(self.buttons) do
        local active = name == state.tool
        b.BackgroundColor3 = if active then C.blue else C.pale
        b.TextColor3 = if active then Color3.new(1, 1, 1) else C.ink
        if (name == "Undo" and not state.canUndo) or (name == "Redo" and not state.canRedo) then b.TextColor3 = C.muted end
    end
    self.snap.Text = if state.snap then "Snap  ON" else "Snap  Fine"
    self.transformSnap.Text = if state.snap then "Snap ON" else "Fine"
    for i, s in ipairs(self.swatches) do s.Color = if i == state.color then C.blue else C.line; s.Thickness = if i == state.color then 3 else 1 end
    for _, row in ipairs(self.rows) do row:Destroy() end
    self.rows = {}
    local counts = {}
    for i, part in ipairs(state.model.parts) do
        counts[part.shape] = (counts[part.shape] or 0) + 1
        local row = button(self.partsList, "    " .. part.shape .. " " .. counts[part.shape], UDim2.new(), UDim2.new(1, -5, 0, 42), function() self.action("SelectPart", part.id) end)
        row.LayoutOrder, row.TextXAlignment = i, Enum.TextXAlignment.Left
        row.BackgroundColor3 = if state.selected == part.id then C.selected else C.pale
        local dot = node("Frame", row, { BackgroundColor3 = Color3.fromRGB(table.unpack(Config.Palette[part.color])), BorderSizePixel = 0, Position = UDim2.fromOffset(10, 15), Size = UDim2.fromOffset(10, 12) })
        round(dot, 3)
        row.Text = "       " .. part.shape .. " " .. counts[part.shape]
        table.insert(self.rows, row)
    end
    if #state.model.parts == 0 then
        table.insert(self.rows, label(self.partsList, "A blank canvas.\nAdd your first shape!", UDim2.new(), UDim2.new(1, -8, 0, 95), 14, C.muted))
    end
    local part = state:part()
    self.partInfo.Text = if part then string.format("%s · %.1f × %.1f × %.1f studs", part.shape, table.unpack(part.size)) else "Select a part to edit"
    self.duplicate.TextColor3 = if part then C.ink else C.muted
    self.delete.TextColor3 = if part then C.ink else C.muted
    local transforming = part and table.find({ "Move", "Rotate", "Scale" }, state.tool) ~= nil and state.mode == "Build"
    self.transformPanel.Visible = transforming == true
    self.transformShadow.Visible = self.transformPanel.Visible
    self.transformTitle.Text = state.tool .. "  ·  " .. state:step() .. (if state.tool == "Rotate" then "° per tap · local rings" else " stud per tap")
    local building = state.mode == "Build"
    for _, object in ipairs({ self.rail, self.railShadow, self.bottom, self.bottomShadow }) do object.Visible = building end
    self.preview.Visible, self.previewShadow.Visible = not building, not building
    self.previewText.Text = #state.model.parts .. " parts. One original idea. Save from the editor to keep a session copy."
    self:layout()
end
function UI:toast(message)
    self.toastId = (self.toastId or 0) + 1
    local id = self.toastId
    self.toastLabel.Text, self.toastLabel.Visible = message, true
    task.delay(3.5, function() if self.toastId == id then self.toastLabel.Visible = false end end)
end
function UI:closeModal()
    if self.modal then self.modal:Destroy(); self.modal = nil end
    self.state.modalOpen = false
    if self.onModalChanged then self.onModalChanged() end
end
function UI:dialog(title, subtitle, height)
    self:closeModal()
    local overlay = node("TextButton", self.root, { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(29, 42, 78), BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1), ZIndex = 50 })
    self.modal = overlay
    self.state.modalOpen = true
    if self.onModalChanged then self.onModalChanged() end
    local body = panel(overlay, UDim2.new(0.5, -220, 0.5, -height / 2), UDim2.fromOffset(440, height))
    body.Active = true
    label(body, title, UDim2.fromOffset(22, 16), UDim2.fromOffset(347, 34), 22)
    label(body, subtitle, UDim2.fromOffset(22, 57), UDim2.fromOffset(396, 50), 13, C.muted)
    button(body, "×", UDim2.new(1, -53, 0, 15), UDim2.fromOffset(34, 34), function() self:closeModal() end)
    return body
end
function UI:confirm(title, description, callback)
    local body = self:dialog(title, description, 194)
    button(body, "Cancel", UDim2.fromOffset(22, 128), UDim2.fromOffset(192, 44), function() self:closeModal() end)
    button(body, "Continue", UDim2.fromOffset(226, 128), UDim2.fromOffset(192, 44), function() self:closeModal(); callback() end, C.blue)
end
function UI:showShapes()
    local body = self:dialog("Start with a shape", "Simple pieces. Endless possibilities. Choose one to add it to your build.", 262)
    for i, shape in ipairs(Config.Shapes) do
        button(body, shape, UDim2.fromOffset(22 + ((i - 1) % 2) * 204, 121 + math.floor((i - 1) / 2) * 61), UDim2.fromOffset(192, 50), function()
            self:closeModal(); self.action("AddShape", shape)
        end, if i == 1 then C.blue else nil)
    end
end
function UI:showLibrary()
    local entries = self.state.library
    local body = self:dialog("Your model library", "Session saves only · " .. #entries .. "/" .. Config.MaxSaves .. " slots\nLeaving this server clears your library.", 458)
    local list = node("ScrollingFrame", body, { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(22, 119), Size = UDim2.fromOffset(396, 317), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4 })
    node("UIListLayout", list, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    if #entries == 0 then label(list, "Your first creation belongs here.\nClose this window and choose Save Model.", UDim2.new(), UDim2.new(1, 0, 0, 100), 15, C.muted) end
    for _, entry in ipairs(entries) do
        local row = node("Frame", list, { BackgroundColor3 = C.pale, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 62) }); round(row, 12)
        label(row, "Model " .. entry.id .. "\n" .. entry.count .. " parts", UDim2.fromOffset(12, 7), UDim2.fromOffset(180, 47), 14)
        button(row, "Load", UDim2.fromOffset(214, 10), UDim2.fromOffset(91, 42), function() self.action("Load", entry.id) end, C.blue)
        button(row, "×", UDim2.fromOffset(317, 10), UDim2.fromOffset(56, 42), function() self.action("RemoveSave", entry.id) end)
    end
end
return UI
