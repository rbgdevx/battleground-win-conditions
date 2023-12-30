local _, NS = ...

local mod = NS.API:NewMod()

local next = next

local instanceIdToMapId = {
  -- Twin Peaks
  [726] = {
    id = 206,
    maxFlags = 1,
    tickRate = 1,
  },
}

function mod:EnterZone(id)
  NS.Info:StartInfoTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].tickRate, {}, instanceIdToMapId[id].maxFlags)
end

function mod:ExitZone()
  NS.Info:StopInfoTracker()
end

for id in next, instanceIdToMapId do
  NS.BGWC:RegisterZone(id, mod)
end
