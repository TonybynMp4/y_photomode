local SendNUIMessage = SendNUIMessage
local config = require 'config.client'

local FOV_MAX = 79.5
local FOV_MIN = 7.6
local DEFAULT_FOV = (FOV_MAX + FOV_MIN) * 0.5
local MAX_DISTANCE = config.maxDistance

--- @type number
local fov = DEFAULT_FOV
--- @type number
local pitch = 0.0
--- @type number
local heading = 0.0
--- @type number
local roll = 0.0
--- @type vector3 | nil
local camCoords = nil
local originCoords = nil

local dofStrength = 0.0
local dof = 0.0
local dofEnd = 0.0
local disabledControls = false
local showControls = false
local relativeCamCoords = false

local cam
local inCam = false

local function inputScaleform(scaleform)
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    local scaleformButtons = {
        { '~INPUT_RELOAD~', locale('scaleform.relative') },
        { '~INPUT_AIM~',             locale('scaleform.mouse') },
        { '~INPUT_VEH_HEADLIGHT~',   locale('scaleform.ui') },
        { '~INPUT_FRONTEND_CANCEL~', locale('scaleform.quit') },
        { '~INPUT_FRONTEND_RS~',     locale('scaleform.slower') },
        { '~INPUT_SPRINT~',          locale('scaleform.faster') },
        { '~INPUT_PICKUP~',          locale('scaleform.up') },
        { '~INPUT_COVER~',           locale('scaleform.down') },
        { '~INPUT_MOVE_UP_ONLY~',    locale('scaleform.forward') },
        { '~INPUT_MOVE_DOWN_ONLY~',  locale('scaleform.backward') },
        { '~INPUT_MOVE_LEFT_ONLY~',  locale('scaleform.left') },
        { '~INPUT_MOVE_RIGHT_ONLY~', locale('scaleform.right') }
    }

    for i = 1, #scaleformButtons, 1 do
        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(i - 1)
        PushScaleformMovieFunctionParameterString(scaleformButtons[i][1])
        PushScaleformMovieFunctionParameterString(scaleformButtons[i][2])
        PopScaleformMovieFunctionVoid()
    end

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PushScaleformMovieFunctionParameterInt(0)
    PopScaleformMovieFunctionVoid()
    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
end

local function resetVariables()
    fov = DEFAULT_FOV
    pitch = 0.0
    heading = 0.0
    roll = 0.0
    camCoords = nil
    dofStrength = 0.0
    dof = 0.0
    dofEnd = 0.0
    disabledControls = false
    showControls = false
end

local function resetCamera()
    SendNUIMessage({
        message = 'show',
        show = false
    })
    SetNuiFocus(false, false)
    inCam = false
    DestroyCam(cam, false)
    cam = nil
    RenderScriptCams(false, true, 0, true, false)
    TriggerEvent("qbx_hud:client:showHud")
    DisplayHud(true)
    DisplayRadar(true)
    ClearTimecycleModifier()
    resetVariables()
end

local function handleMouseControls()
    local multiplier = fov / 50
    heading -= (GetDisabledControlNormal(2, 1) * (5 * multiplier))
    pitch -= (GetDisabledControlNormal(2, 2) * (5 * multiplier))

    pitch = math.clamp(pitch, -90.0, 90.0)
    SetCamRot(cam, pitch, roll, heading, 2)
end

local function handleKeyboardControls()
    local speed = 0.1
    local moveForward = 0
    local moveRight = 0
    local moveUp = 0

    if IsDisabledControlPressed(0, 21) then
        speed = speed * 2
    end

    if IsDisabledControlPressed(0, 210) then
        speed = speed / 2
    end

    -- Down
    if IsDisabledControlPressed(0, 44) then
        moveUp += -speed
    end

    -- Up
    if IsDisabledControlPressed(0, 38) then
        moveUp += speed
    end

    -- Forward
    if IsDisabledControlPressed(0, 32) then
        moveForward += speed
    end

    -- Backward
    if IsDisabledControlPressed(0, 33) then
        moveForward += -speed
    end

    -- Left
    if IsDisabledControlPressed(0, 34) then
        moveRight += -speed
    end

    -- Right
    if IsDisabledControlPressed(0, 35) then
        moveRight += speed
    end

    if camCoords == nil then
        camCoords = GetCamCoord(cam)
    end

    return vector3(moveForward, moveRight, moveUp)
end

local function updateCameraCoords(moveVector)
    local rightVector, forwardVector, upVector, position = GetCamMatrix(cam)
    if moveVector then
        position += forwardVector * moveVector.x + rightVector * moveVector.y + upVector * moveVector.z
    end

    -- follow the ped
    if relativeCamCoords then
        local newOrigin = GetEntityCoords(cache.ped)
        position = newOrigin + (position - originCoords)
        originCoords = newOrigin
    end

    local distance = #(originCoords - position)
    if distance > MAX_DISTANCE then
        position = originCoords + (position - originCoords) / distance * MAX_DISTANCE
    end

    camCoords = position

    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
end

local function disableControlsThisFrame()
    DisableAllControlActions(0)
    DisablePlayerFiring(cache.playerId, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 44, true)
end

local function disableControls()
    disabledControls = not disabledControls
    Wait(100)
    SetNuiFocus(disabledControls, disabledControls)
end

RegisterNUICallback('onDisableControls', function(data, cb)
    disableControls()
    cb({})
end)

local function toggleUI()
    showControls = not showControls
    SendNUIMessage({
        message = 'show',
        show = showControls
    })
    if not showControls then
        SetNuiFocus(false, false)
    end
end

RegisterNUICallback('onToggleUI', function(data, cb)
    toggleUI()
    cb({})
end)

local function openCamera()
    SetNuiFocus(false, false)
    DisplayHud(false)
    DisplayRadar(false)
    TriggerEvent("qbx_hud:client:hideHud")
    inCam = true
    SetTimecycleModifier("default")

    heading = GetEntityHeading(cache.ped)
    originCoords = GetEntityCoords(cache.ped)
    camCoords = GetGameplayCamCoord()

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(cam, 0.0, 0.0, heading, 2)
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, true, false)
    SetCamUseShallowDofMode(cam, true)
    toggleUI()

    local scaleform = lib.requestScaleformMovie("instructional_buttons", 10000)
    CreateThread(function()
        local moveVector
        while inCam do
            moveVector = nil
            disableControlsThisFrame()
            if not disabledControls then
                handleMouseControls()
                moveVector = handleKeyboardControls()
            end
            if showControls then
                inputScaleform(scaleform)
            end
            updateCameraCoords(moveVector)

            SetUseHiDof()
            SetCamDofFocalLengthMultiplier(cam, 2.5)

            if IsDisabledControlJustPressed(1, 45) then
                relativeCamCoords = not relativeCamCoords
            end

            if IsDisabledControlJustPressed(1, 202) then
                inCam = false
                resetCamera()
            end

            if showControls and IsDisabledControlJustPressed(1, 25) then
                disableControls()
            end

            if IsDisabledControlJustPressed(1, 74) then
                toggleUI()
            end
            Wait(0)
        end
    end)
end

RegisterNUICallback('onClose', function(_, cb)
    resetCamera()
    cb({})
end)

RegisterNUICallback('onFovChange', function(data, cb)
    local NUIfov = tonumber(data.fov)
    if not NUIfov then return end

    fov = math.clamp(NUIfov, FOV_MIN, FOV_MAX)
    SetCamFov(cam, fov)
    cb({})
end)

RegisterNUICallback('onRollChange', function(data, cb)
    local NUIroll = tonumber(data.roll)
    if not NUIroll then return end

    roll = NUIroll
    SetCamRot(cam, pitch, roll, heading, 2)
    cb({})
end)

RegisterNUICallback('onDofStartChange', function(data, cb)
    local NUIdof = tonumber(data.dofStart)
    if not NUIdof then return end

    dof = NUIdof
    SetCamNearDof(cam, dof)
    cb({})
end)

RegisterNUICallback('onDofEndChange', function(data, cb)
    local NUIdofEnd = tonumber(data.dofEnd)
    if not NUIdofEnd then return end

    dofEnd = NUIdofEnd
    SetCamFarDof(cam, dofEnd)
    cb({})
end)

RegisterNUICallback('onDofStrengthChange', function(data, cb)
    local NUIdofStrength = tonumber(data.dofStrength)
    if not NUIdofStrength then return end

    dofStrength = NUIdofStrength
    SetCamDofStrength(cam, dofStrength / 100)
    cb({})
end)

RegisterNUICallback('getLocales', function(_, cb)
    cb({
        fov = locale('ui.fov'),
        roll = locale('ui.roll'),
        dofStart = locale('ui.dofStart'),
        dofEnd = locale('ui.dofEnd'),
        dofStrength = locale('ui.dofStrength')
    })
end)

lib.addKeybind({
    name = 'photomode',
    description = locale('open'),
    defaultKey = config.openKeybind,
    onPressed = function()
        if inCam then
            resetCamera()
            return
        end

        openCamera()
    end
})
