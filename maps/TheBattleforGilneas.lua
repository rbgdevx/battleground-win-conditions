local _, NS = ...

local mod = NS.API:NewMod()

local next = next

local instanceIdToMapId = {
  -- Gilneas
  [761] = {
    id = 275,
    maxBases = 3,
    tickRate = 1,
    resourcesFromBases = {
      [0] = 0,
      [1] = 1,
      [2] = 3,
      [3] = 30,
    },
  },
}

function mod:EnterZone(id)
  NS.Info:StartInfoTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].tickRate, {
    baseResources = instanceIdToMapId[id].resourcesFromBases,
  }, instanceIdToMapId[id].maxBases)
end

function mod:ExitZone()
  NS.Info:StopInfoTracker()
end

for id in next, instanceIdToMapId do
  NS.BGWC:RegisterZone(id, mod)
end
