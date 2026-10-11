local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Input = {}
function Input.bind(state, ui, camera, transform, scene, action)
    local rotating, panning, last, touch, start, touchMoved
    local function overUI(position)
        for _, object in ipairs(Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(position.X, position.Y)) do
            if object:IsA("GuiButton") or object:IsA("ScrollingFrame") or (object:IsA("Frame") and object.BackgroundTransparency < 1) then return true end
        end
        return false
    end
    local function selectAt(position)
        if state.mode ~= "Build" or state.busy or ui.modal or transform.dragging then return end
        local id = scene:pick(position)
        if id then action("SelectPart", id) end
    end
    UIS.InputBegan:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if UIS:GetFocusedTextBox() or processed then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                if ui.modal then ui:closeModal() elseif transform.dragging then transform:finish(true) else action("Select") end
                return
            end
            if ui.modal or transform.dragging then return end
            local ctrl = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
            local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
            if ctrl then
                local keys = { [Enum.KeyCode.Z] = if shift then "Redo" else "Undo", [Enum.KeyCode.Y] = "Redo", [Enum.KeyCode.D] = "Duplicate", [Enum.KeyCode.S] = "Save" }
                if keys[input.KeyCode] then action(keys[input.KeyCode]) end
            else
                local keys = { [Enum.KeyCode.Q] = "Select", [Enum.KeyCode.W] = "Move", [Enum.KeyCode.E] = "Rotate", [Enum.KeyCode.R] = "Scale",
                    [Enum.KeyCode.B] = "Paint", [Enum.KeyCode.F] = "Focus", [Enum.KeyCode.N] = "Add", [Enum.KeyCode.Delete] = "Delete" }
                if keys[input.KeyCode] then action(keys[input.KeyCode]) end
            end
            return
        end
        local position = Vector2.new(input.Position.X, input.Position.Y)
        if processed or ui.modal or overUI(position) then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then rotating = true; last = UIS:GetMouseLocation()
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then panning = true; last = UIS:GetMouseLocation()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Handles claim a press before a deferred scene selection can replace the selection.
            task.defer(function() if not transform.dragging then selectAt(position) end end)
        elseif input.UserInputType == Enum.UserInputType.Touch and not touch then
            touch, start, last, touchMoved = input, position, position, false
        end
    end)
    UIS.InputChanged:Connect(function(input, processed)
        if ui.modal then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel and not processed and not overUI(UIS:GetMouseLocation()) then camera:zoom(input.Position.Z)
        elseif input.UserInputType == Enum.UserInputType.MouseMovement and (rotating or panning) then
            local position = UIS:GetMouseLocation()
            if last then
                if panning then camera:pan(position - last) else camera:orbit(position - last) end
            end
            last = position
        elseif input == touch then
            local position = Vector2.new(input.Position.X, input.Position.Y)
            if (position - start).Magnitude > 10 then touchMoved = true end
            if touchMoved and not transform.dragging then camera:orbit(position - last) end
            last = position
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then rotating = false end
        if input.UserInputType == Enum.UserInputType.MouseButton3 then panning = false end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then transform:finish(false) end
        if input == touch then
            if not touchMoved then selectAt(Vector2.new(input.Position.X, input.Position.Y)) end
            transform:finish(false)
            touch = nil
        end
    end)
    UIS.WindowFocusReleased:Connect(function()
        rotating, panning, touch = false, false, nil
        transform:finish(true)
    end)
end
return Input
