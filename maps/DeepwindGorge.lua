local _, NS = ...

local mod = NS.API:NewMod()

local instanceIdToMapId = {
  -- DeepwindGorge
  [2245] = {
    id = 1576,
    maxBases = 5,
    tickRate = 2,
    resourcesFromBases = {
      [0] = 0,
      [1] = 1,
      [2] = 1.5,
      [3] = 2,
      [4] = 3.5,
      [5] = 30,
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
