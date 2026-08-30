-- Native macOS Space controls for Hammerspoon.
-- Shortcuts use Command+Control+Shift to avoid the current Amethyst bindings.

-- Use the left Command key. The right Command key is a Karabiner layer here.
local SPACE_MODS = {"cmd", "ctrl", "shift"}
local S = hs.spaces

-- Mission Control's accessibility tree needs time to appear.
S.MCwaitTime = 0.6

local function api(fn, ...)
    local ok, first, second = pcall(fn, ...)
    if not ok then
        return nil, first
    end
    if first == nil or first == false then
        return nil, second or "operation failed"
    end
    return first, second
end

-- Return the focused Space and its display, including full-screen Spaces.
local function spaceContext()
    local current, err = api(S.focusedSpace)
    if not current then
        return nil, err
    end

    local kind, kindErr = api(S.spaceType, current)
    if not kind then
        return nil, kindErr
    end

    local display, displayErr = api(S.spaceDisplay, current)
    if not display then
        return nil, displayErr
    end

    local all, allErr = api(S.spacesForScreen, display)
    if not all then
        return nil, allErr
    end

    local userSpaces = {}
    local currentIndex
    for _, id in ipairs(all) do
        local spaceKind = api(S.spaceType, id)
        if spaceKind == "user" then
            userSpaces[#userSpaces + 1] = id
            if id == current then
                currentIndex = #userSpaces
            end
        end
    end

    return {
        current = current,
        kind = kind,
        display = display,
        userSpaces = userSpaces,
        index = currentIndex,
    }
end

local function currentContext()
    local context, err = spaceContext()
    if not context then
        return nil, err
    end

    if context.kind ~= "user" then
        return nil, "the focused space is a full-screen or Split View space; press the exit shortcut first"
    end

    if not context.index then
        return nil, "the focused space was not found on its display"
    end

    return context
end

local function adjacentSpace(context)
    return context.userSpaces[context.index - 1]
        or context.userSpaces[context.index + 1]
end

local operation
local createTimer
local deleteTimer
local exitTimer

local function beginOperation(name)
    if operation then
        hs.alert.show("Space operation in progress")
        return false
    end
    operation = name
    return true
end

local function finishOperation()
    operation = nil
    createTimer = nil
    deleteTimer = nil
    exitTimer = nil
end

-- Create a native Space on the focused display and switch to it.
local function createSpace()
    if not beginOperation("create") then
        return
    end

    local context, err = spaceContext()
    if not context then
        finishOperation()
        hs.alert.show("Create Space failed: " .. tostring(err))
        return
    end

    local before = {}
    for _, id in ipairs(context.userSpaces) do
        before[id] = true
    end

    local created, createErr = api(S.addSpaceToScreen, context.display)
    if not created then
        finishOperation()
        hs.alert.show("Create Space failed: " .. tostring(createErr))
        return
    end

    -- The new ID is not always visible immediately after Mission Control closes.
    local attempts = 0
    local function switchToNewSpace()
        local ids = api(S.spacesForScreen, context.display)
        if ids then
            for _, id in ipairs(ids) do
                local kind = api(S.spaceType, id)
                if not before[id] and kind == "user" then
                    local switched, switchErr = api(S.gotoSpace, id)
                    finishOperation()
                    if switched then
                        hs.alert.show("Created and switched to a new Space")
                    else
                        hs.alert.show("Space created, but switching failed: " .. tostring(switchErr))
                    end
                    return
                end
            end
        end

        attempts = attempts + 1
        if attempts < 12 then
            createTimer = hs.timer.doAfter(0.25, switchToNewSpace)
        else
            finishOperation()
            hs.alert.show("Space created, but the new Space could not be identified")
        end
    end

    createTimer = hs.timer.doAfter(0.25, switchToNewSpace)
end

-- Exit the focused application's native full-screen mode.
local function exitFullscreen()
    if not beginOperation("exit-fullscreen") then
        return
    end

    local window = hs.window.focusedWindow()
    if not window then
        finishOperation()
        hs.alert.show("No focused window; press Control+Command+F")
        return
    end

    local ok, result = pcall(function()
        return window:setFullScreen(false)
    end)

    if not ok or not result then
        finishOperation()
        hs.alert.show("Could not exit full-screen; press Control+Command+F")
        return
    end

    exitTimer = hs.timer.doAfter(0.4, function()
        local current = api(S.focusedSpace)
        local kind = current and api(S.spaceType, current)
        finishOperation()
        if kind == "user" then
            hs.alert.show("Exited full-screen")
        else
            hs.alert.show("Full-screen exit may still be in progress")
        end
    end)
end

-- Move ordinary windows out of the focused Space without closing their apps.
local function clearSpace()
    if not beginOperation("clear") then
        return
    end

    local context, err = currentContext()
    if not context then
        finishOperation()
        hs.alert.show("Clear Space failed: " .. tostring(err))
        return
    end

    local target = adjacentSpace(context)
    if not target then
        finishOperation()
        hs.alert.show("At least two regular desktop Spaces are required")
        return
    end

    local windowsOK, windows = pcall(hs.window.allWindows)
    if not windowsOK then
        finishOperation()
        hs.alert.show("Could not read windows in the current Space")
        return
    end

    local moved = 0
    local failed = 0

    for _, window in ipairs(windows) do
        local standardOK, standard = pcall(function()
            return window:isStandard()
        end)
        local fullscreenOK, fullscreen = pcall(function()
            return window:isFullScreen()
        end)

        if standardOK and standard and fullscreenOK and fullscreen ~= true then
            local memberships = api(S.windowSpaces, window)
            -- Skip windows assigned to All Desktops or other multiple Spaces.
            if memberships
                and #memberships == 1
                and memberships[1] == context.current
            then
                local movedOK = api(S.moveWindowToSpace, window, target)
                if movedOK then
                    moved = moved + 1
                else
                    failed = failed + 1
                end
            end
        end
    end

    finishOperation()
    hs.alert.show(string.format(
        "Moved %d window(s)%s",
        moved,
        failed > 0 and string.format("; %d failed", failed) or ""
    ))
end

-- The focused Space cannot be removed, so switch away before removing it.
local function deleteCurrentSpace()
    if not beginOperation("delete") then
        return
    end

    local context, err = currentContext()
    if not context then
        finishOperation()
        hs.alert.show("Delete Space failed: " .. tostring(err))
        return
    end

    if #context.userSpaces <= 1 then
        finishOperation()
        hs.alert.show("The last regular desktop Space cannot be deleted")
        return
    end

    local target = adjacentSpace(context)

    local switched, switchErr = api(S.gotoSpace, target)
    if not switched then
        finishOperation()
        hs.alert.show("Could not switch away from Space: " .. tostring(switchErr))
        return
    end

    local attempts = 0
    local function removeWhenInactive()
        local active, activeErr = api(S.focusedSpace)
        if not active then
            finishOperation()
            hs.alert.show("Could not confirm the active Space: " .. tostring(activeErr))
            return
        end

        if active ~= target then
            attempts = attempts + 1
            if attempts < 15 then
                deleteTimer = hs.timer.doAfter(0.2, removeWhenInactive)
            else
                finishOperation()
                hs.alert.show("Space switch timed out; nothing was deleted")
            end
            return
        end

        local removed, removeErr = api(S.removeSpace, context.current)
        if not removed then
            finishOperation()
            hs.alert.show("Delete Space failed: " .. tostring(removeErr))
            return
        end

        -- removeSpace reports that removal was initiated, so verify the ID.
        local verifyAttempts = 0
        local function confirmRemoved()
            local ids, scanErr = api(S.spacesForScreen, context.display)
            if not ids then
                finishOperation()
                hs.alert.show("Could not verify Space removal: " .. tostring(scanErr))
                return
            end

            for _, id in ipairs(ids) do
                if id == context.current then
                    verifyAttempts = verifyAttempts + 1
                    if verifyAttempts < 15 then
                        deleteTimer = hs.timer.doAfter(0.25, confirmRemoved)
                    else
                        finishOperation()
                        hs.alert.show("Space removal was initiated but not confirmed")
                    end
                    return
                end
            end

            finishOperation()
            hs.alert.show("Deleted Space")
        end

        deleteTimer = hs.timer.doAfter(0.3, confirmRemoved)
    end

    deleteTimer = hs.timer.doAfter(0.3, removeWhenInactive)
end

-- Require a second press within two seconds for the destructive action.
local deleteArmed = false
local deleteArmTimer

local function requestDelete()
    if operation then
        hs.alert.show("Space operation in progress")
        return
    end

    if not deleteArmed then
        deleteArmed = true
        hs.alert.show("Press the delete shortcut again to delete this Space")
        deleteArmTimer = hs.timer.doAfter(2, function()
            deleteArmed = false
            deleteArmTimer = nil
        end)
        return
    end

    deleteArmed = false
    if deleteArmTimer then
        deleteArmTimer:stop()
        deleteArmTimer = nil
    end
    deleteCurrentSpace()
end

hs.hotkey.bind(SPACE_MODS, "n", createSpace)
hs.hotkey.bind(SPACE_MODS, "e", clearSpace)
hs.hotkey.bind(SPACE_MODS, "d", requestDelete)
hs.hotkey.bind(SPACE_MODS, "f", exitFullscreen)

hs.alert.show("Hammerspoon Space shortcuts loaded")
