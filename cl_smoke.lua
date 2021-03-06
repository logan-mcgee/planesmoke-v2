local sr, sg, sb = config.defaults.r, config.defaults.g, config.defaults.b
local ss = config.defaults.size

currentPtfx = {}

Citizen.CreateThread(function ()
  DecorRegister("smoke_active", 2)
  DecorRegister("smoke_color", 3)
  DecorRegister("smoke_size", 1)

  local fxDict = "scr_ar_planes"
  local fxName = "scr_ar_trail_smoke"

  RequestNamedPtfxAsset(fxDict)

  while not HasNamedPtfxAssetLoaded(fxDict) do
    Wait(0)
  end

  while true do
    Wait(500)
    for _, player in ipairs(GetActivePlayers()) do
      local ped = GetPlayerPed(player)
      if (shouldPedHaveSmoke(ped)) then
        local veh = GetVehiclePedIsIn(ped, false)
        if DecorGetBool(veh, "smoke_active") then
          local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(veh))
          if not currentPtfx[veh] and dist < config.maxdist then
            local vehModel = GetEntityModel(veh)
            local r, g, b = decodeSmoke(DecorGetInt(veh, "smoke_color"))
            local size = DecorGetFloat(veh, "smoke_size")

            local outputPos
            if (config.offsets[vehModel]) then
              outputPos = vector3(config.offsets[vehModel][1], config.offsets[vehModel][2], config.offsets[vehModel][3])
            else
              local min, max = GetModelDimensions(GetEntityModel(veh))
              local offset = vector3(0.0, min.y, 0.0)
              outputPos = offset
            end
            UseParticleFxAssetNextCall(fxDict)
            currentPtfx[veh] = StartParticleFxLoopedOnEntityBone_2(fxName, veh, outputPos, 0.0, 0.0, 0.0, -1, size + 0.0, outputPos)

            SetParticleFxLoopedScale(currentPtfx[veh], size + 0.0)
            SetParticleFxLoopedRange(currentPtfx[veh], 1000.0)
            SetParticleFxLoopedColour(currentPtfx[veh], r + 0.0, g + 0.0, b + 0.0)
          elseif currentPtfx[veh] and dist < config.maxdist then
            local r, g, b = decodeSmoke(DecorGetInt(veh, "smoke_color"))
            local size = DecorGetFloat(veh, "smoke_size")

            SetParticleFxLoopedScale(currentPtfx[veh], size + 0.0)
            SetParticleFxLoopedRange(currentPtfx[veh], 1000.0)
            SetParticleFxLoopedColour(currentPtfx[veh], r + 0.0, g + 0.0, b + 0.0)
          end
        elseif not DecorGetBool(veh, "smoke_active") and currentPtfx[veh] then
          StopParticleFxLooped(currentPtfx[veh], 0)
          currentPtfx[veh] = nil
        end
      end
    end

    for veh, ptfx in pairs(currentPtfx) do
      if (IsEntityDead(veh) or not DoesEntityExist(veh)) then
        stopSmoke(veh)
      end
      if (config.perf) then
        if (IsVehicleSeatFree(veh, -1) or GetEntityHeightAboveGround(veh) <= 1.5 or not IsEntityInAir(veh)) then
          stopSmoke(veh)
        end

        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(veh))
        if (dist > config.maxdist) then
          StopParticleFxLooped(currentPtfx[veh], 0)
          currentPtfx[veh] = nil
        end
      end
    end
  end
end)

if (config.dev) then
  Citizen.CreateThread(function()
    RequestStreamedTextureDict("helicopterhud")
    while not HasStreamedTextureDictLoaded("helicopterhud") do Wait(0) end
    while true do
      Wait(0)
      local ped = PlayerPedId()
      if (shouldPedHaveSmoke(ped)) then

        local outputPos
        local veh = GetVehiclePedIsIn(ped, false)
        local vehModel = GetEntityModel(veh)
        if (config.offsets[vehModel]) then
          outputPos = vector3(config.offsets[vehModel][1], config.offsets[vehModel][2], config.offsets[vehModel][3])
        else
          local min, max = GetModelDimensions(GetEntityModel(veh))
          local offset = vector3(0.0, min.y, 0.0)
          outputPos = offset
        end

        local min, max = GetModelDimensions(GetEntityModel(veh))
        local offset = GetOffsetFromEntityInWorldCoords(veh, outputPos)
        DrawLine(GetEntityCoords(veh), offset, 0, 255, 0, 255)
        SetDrawOrigin(offset)
        DrawSprite("helicopterhud", "hud_dest", 0.0, 0.0, 0.02, 0.03, 0.0, 0, 255, 0, 255)
        ClearDrawOrigin()
      end
    end
  end)
end

function doToggle()
  local plyr = PlayerPedId()
  if (shouldPedHaveSmoke(plyr)) then
    local veh = GetVehiclePedIsIn(plyr, false)
    if ((GetEntityHeightAboveGround(veh) >= 1.5 or IsEntityInAir(veh)) and not IsVehicleOnAllWheels(veh)) then
      DecorSetBool(veh, "smoke_active", not DecorGetBool(veh, "smoke_active"))
      DecorSetInt(veh, "smoke_color", encodeSmoke(sr, sg, sb))
      DecorSetFloat(veh, "smoke_size", ss)
    end
  end
end

RegisterCommand("setsmoke", function(src, args, raw)
  local plyr = PlayerPedId()
  sr, sg, sb, ss = tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), (tonumber(args[4]) * 1.0)
  if (sr and sg and sb and ss) then
    if (ss > config.maxsize) then
      ss = config.maxsize
    elseif (ss < 0.1) then
      ss = 0.1
    end

    if (sr > 255) then sr = 255 elseif (sr < 0) then sr = 0 end
    if (sg > 255) then sg = 255 elseif (sg < 0) then sg = 0 end
    if (sb > 255) then sb = 255 elseif (sb < 0) then sb = 0 end

    TriggerEvent("chat:addMessage", {
      color = { 255, 0, 0 },
      multiline = true,
      args = {"Smokester", "Set smoke settings to R: ^8"..sr.."^7, G: ^2"..sg.."^7, B: ^4"..sb.."^7, Size: "..ss}
    })

    if (shouldPedHaveSmoke(plyr)) then
      local veh = GetVehiclePedIsIn(plyr, false)
      DecorSetInt(veh, "smoke_color", encodeSmoke(sr, sg, sb))
      DecorSetFloat(veh, "smoke_size", ss)
    end
  else
    TriggerEvent("chat:addMessage", {
      color = { 255, 0, 0 },
      multiline = true,
      args = {"Smokester", "Incorrect usage. Usage: /setsmoke r g b size"}
    })
  end
end)

RegisterCommand("+togglesmoke", function () doToggle() end, false)
RegisterCommand("-togglesmoke", function () end, false)
RegisterKeyMapping("+togglesmoke", "Toggle plane smoke", "keyboard", "z")