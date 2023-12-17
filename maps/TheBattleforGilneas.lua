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
  NS.Info:StartBaseTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].maxBases, 60)
  NS.Info:StartScoreTracker(
    instanceIdToMapId[id].id,
    instanceIdToMapId[id].resourcesFromBases,
    instanceIdToMapId[id].tickRate,
    {}
  )
end

function mod:ExitZone()
  NS.Info:StopScoreTracker()
  NS.Info:StopBaseTracker()
end

for id in next, instanceIdToMapId do
  NS.BGWC:RegisterZone(id, mod)
end
