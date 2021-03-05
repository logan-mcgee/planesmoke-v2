function decodeSmoke(int)
  local r = (int >> 16) & 0xff
  local g = (int >> 8) & 0xff
  local b = int & 0xff
  return r, g, b
end

function encodeSmoke(r, g, b)
  local newSmoke = ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF)
  return newSmoke
end

function stopSmoke(veh)
  DecorSetBool(veh, "smoke_active", false)
  StopParticleFxLooped(currentPtfx[veh], 0)
  currentPtfx[veh] = nil
end