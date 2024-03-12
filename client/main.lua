local FOV_MAX = 79.5
local FOV_MIN = 7.6
local DEFAULT_FOV = (FOV_MAX + FOV_MIN) * 0.5

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

local dofStrength = 0.0
local dof = 0.0
local dofEnd = 0.0
local disabledControls = false
local camSpeed = 1.0

local cam
local inCam = false
local cameraProp

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
    camSpeed = 1.0
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
    heading -= (GetControlNormal(2, 1) * (5 * multiplier))
    pitch -= (GetControlNormal(2, 2) * (5 * multiplier))
    ---@diagnostic disable-next-line: undefined-field
    pitch = math.clamp(pitch, -90.0, 90.0)
    SetCamRot(cam, pitch, roll, heading, 2)
end

local function handleKeyboardControls()
    local speed = multiplier
    local displacementVector = vector3(0, 0, 0)
    if IsControlPressed(0, 21) then
        speed = speed * 2
    end

    if IsControlPressed(0, 210) then
        speed = speed / 2
    end

    -- Down
    if IsControlPressed(0, 44) then
        displacementVector += vector3(0, 0, -speed)
    end

    -- Forward
    if IsControlPressed(0, 32) then
        displacementVector += vector3(0, 0, speed)
    end

    -- Backward
    if IsControlPressed(0, 33) then
        displacementVector += vector3(-speed, 0, 0)
    end

    -- Left
    if IsControlPressed(0, 34) then
        displacementVector += vector3(0, -speed, 0)
    end

    -- Right
    if IsControlPressed(0, 35) then
        displacementVector += vector3(0, speed, 0)
    end

    if camCoords == nil then
        camCoords = GetCamCoord(cam)
    end

    camCoords += displacementVector
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
end

local function toggleUI()
    SendNUIMessage({
        message = 'show',
        show = true
    })
    disabledControls = not disabledControls
end

local function openCamera()
    SetNuiFocus(false, false)
    DisplayHud(false)
    DisplayRadar(false)
    inCam = true
    SetTimecycleModifier("default")

    heading = GetEntityHeading(cache.ped)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    AttachCamToEntity(cam, cameraProp, 0.075, -0.30, 0, true)
    SetCamRot(cam, 0.0, 0.0, GetEntityHeading(cameraProp) / 360, 2)
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, true, false)

    SendNUIMessage({
        message = 'show',
        show = true
    })
    SetNuiFocus(true, true)

    -- wtf does that do? needs testing
    SetCamUseShallowDofMode(cam, true)

    CreateThread(function()
        while inCam do
            helpText()
            if not disabledControls then
                handleMouseControls()
                handleKeyboardControls()
            end

            SetUseHiDof()

            if IsControlJustPressed(1, 202) then
                inCam = false
                resetCamera()
            elseif IsControlJustPressed(1, 74) then
                toggleUI()
            end
            Wait(0)
        end
    end)
end

lib.addKeybind({
    name = 'photomode',
    description = 'Open the photo mode',
    defaultKey = 'F7',
    onPressed = function()
        if not inCam then
            openCamera()
        else
            resetCamera()
        end
    end
})

RegisterNetEvent('qbx_camera:client:openPhoto', function(source, data)
    SendNUIMessage({
        message = 'photo',
        toggle = true,
        source = source,
        title = data.title,
        subText = data.description
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('onFovChange', function(data, cb)
    fov = data.fov
    SetCamFov(cam, fov)
    cb({})
end)

RegisterNUICallback('onRollChange', function(data, cb)
    roll = data.roll
    SetCamRot(cam, pitch, roll/100, heading, 2)
    cb({})
end)

RegisterNUICallback('onDofChange', function(data, cb)
    dof = data.dof
    SetCamNearDof(cam, dof)
    cb({})
end)

RegisterNUICallback('onDofEndChange', function(data, cb)
    dofEnd = data.dofEnd
    SetCamFarDof(cam, dofEnd)
    cb({})
end)

RegisterNUICallback('onDofStrengthChange', function(data, cb)
    dofStrength = data.dofStrength
    SetCamDofStrength(cam, dofStrength)
    cb({})
end)