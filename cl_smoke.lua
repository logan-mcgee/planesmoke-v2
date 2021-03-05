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
      if (IsPedInAnyPlane(ped)) then
        local veh = GetVehiclePedIsIn(ped, false)
        if DecorGetBool(veh, "smoke_active") then
          if not currentPtfx[veh] then
            local vehModel = GetEntityModel(veh)
            local r, g, b = decodeSmoke(DecorGetInt(veh, "smoke_color"))
            local size = DecorGetFloat(veh, "smoke_size")

            local ox, oy, oz
            if (config.offsets[vehModel]) then
              ox, oy, oz = config.offsets[vehModel][1], config.offsets[vehModel][2], config.offsets[vehModel][3]
            else
              ox, oy, oz = 0.0, -3.0, 0.0
            end

            UseParticleFxAssetNextCall(fxDict)
            currentPtfx[veh] = StartParticleFxLoopedOnEntityBone_2(fxName, veh, ox, oy, oz, 0.0, 0.0, 0.0, (config.offsets[vehModel] and -1 or GetEntityBoneIndexByName(veh, "engine")), size + 0.0, ox, oy, oz)
            
            SetParticleFxLoopedScale(currentPtfx[veh], size + 0.0)
					  SetParticleFxLoopedRange(currentPtfx[veh], 1000.0)
					  SetParticleFxLoopedColour(currentPtfx[veh], r + 0.0, g + 0.0, b + 0.0)
          else
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
        if (IsEntityDead(veh)) then
          stopSmoke(veh)
        end

        if (config.perf and IsVehicleSeatFree(veh, -1)) then
          stopSmoke(veh)
        end
      end
    end
end)

function doToggle()
  local plyr = PlayerPedId()
  if (IsPedInAnyPlane(plyr)) then
    local plane = GetVehiclePedIsIn(plyr, false)

    DecorSetBool(plane, "smoke_active", not DecorGetBool(plane, "smoke_active"))
    DecorSetInt(plane, "smoke_color", encodeSmoke(sr, sg, sb))
    DecorSetFloat(plane, "smoke_size", ss)
  end
end

RegisterCommand("setsmoke", function(src, args, raw)
  local plyr = PlayerPedId()
  if (IsPedInAnyPlane(plyr)) then
    local plane = GetVehiclePedIsIn(plyr, false)
    sr, sg, sb, ss = tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])

    DecorSetInt(plane, "smoke_color", encodeSmoke(sr, sg, sb))
    DecorSetFloat(plane, "smoke_size", ss)
  end
end)

RegisterCommand('+togglesmoke', function () doToggle() end, false)
RegisterCommand('-togglesmoke', function () end, false)
RegisterKeyMapping('+togglesmoke', 'Toggle plane smoke', 'keyboard', 'z')