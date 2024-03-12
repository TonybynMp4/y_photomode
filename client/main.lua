local SendNUIMessage = SendNUIMessage

local FOV_MAX = 79.5
local FOV_MIN = 7.6
local DEFAULT_FOV = (FOV_MAX + FOV_MIN) * 0.5
local MAX_DISTANCE = 25.0

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

local cam
local inCam = false

local function helpText()
    SetTextComponentFormat("STRING")
    AddTextComponentString(locale('help.exit')..': ~INPUT_CELLPHONE_CANCEL~\n'..locale('help.take')..': ~INPUT_CELLPHONE_SELECT~')
    DisplayHelpTextFromStringLabel(0, false, true, 1)
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
    DisplayHud(true)
    DisplayRadar(true)
    ClearTimecycleModifier()
    resetVariables()
end

local function handleMouseControls()
    local multiplier = fov / 50
    heading -= (GetDisabledControlNormal(2, 1) * (5 * multiplier))
    pitch -= (GetDisabledControlNormal(2, 2) * (5 * multiplier))
    ---@diagnostic disable-next-line: undefined-field
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

    local rightVector, forwardVector, upVector, position = GetCamMatrix(cam)
    position += forwardVector * moveForward + rightVector * moveRight + upVector * moveUp

    local distance = #(originCoords - position)
    if distance > MAX_DISTANCE then
        position = originCoords + (position - originCoords) / distance * MAX_DISTANCE
    end

    camCoords = position

    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
end

local function disableKeyboard()
    DisableAllControlActions(0)
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

    toggleUI()

    -- wtf does that do? needs testing
    SetCamUseShallowDofMode(cam, false)

    CreateThread(function()
        while inCam do
            disableKeyboard()
            helpText()
            if not disabledControls then
                handleMouseControls()
                handleKeyboardControls()
            end

            SetUseHiDof()

            if IsDisabledControlJustPressed(1, 202) then
                inCam = false
                resetCamera()
            elseif showControls and IsDisabledControlJustPressed(1, 25) then
                disableControls()
            elseif IsDisabledControlJustPressed(1, 74) then
                toggleUI()
            end
            Wait(0)
        end
    end)
end

lib.addKeybind({
    name = 'photomode',
    description = 'Open the photo mode',
    defaultKey = 'F5',
    onPressed = function()
        if inCam then
            resetCamera()
            return
        end

        openCamera()
    end
})

RegisterNUICallback('onClose', function (body, cb)
    resetCamera()
    cb({})
end)

RegisterNUICallback('onFovChange', function(data, cb)
    fov = tonumber(data.fov)
    SetCamFov(cam, fov)
    cb({})
end)

RegisterNUICallback('onRollChange', function(data, cb)
    roll = tonumber(data.roll)
    SetCamRot(cam, pitch, roll, heading, 2)
    cb({})
end)

RegisterNUICallback('onDofChange', function(data, cb)
    dof = tonumber(data.dof)
    SetCamNearDof(cam, dof)
    cb({})
end)

RegisterNUICallback('onDofEndChange', function(data, cb)
    dofEnd = tonumber(data.dofEnd)
    SetCamFarDof(cam, dofEnd)
    cb({})
end)

RegisterNUICallback('onDofStrengthChange', function(data, cb)
    dofStrength = tonumber(data.dofStrength)
    SetCamDofStrength(cam, dofStrength)
    cb({})
end)