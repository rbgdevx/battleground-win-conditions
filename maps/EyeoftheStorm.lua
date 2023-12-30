local _, NS = ...

local mod = NS.API:NewMod()

local next = next

local instanceIdToMapId = {
  -- EyeoftheStorm
  -- only iconState 1 has flag info
  -- "TEAM has taken the flag"
  [566] = {
    id = 112,
    maxBases = 4,
    tickRate = 2,
    resourcesFromBases = {
      [0] = 0,
      [1] = 1,
      [2] = 1.5,
      [3] = 2,
      [4] = 6,
    },
    resourcesFromFlags = {
      [0] = 0,
      [1] = 75,
      [2] = 85,
      [3] = 100,
      [4] = 500,
    },
  },
  -- RatedEyeoftheStorm
  [968] = {
    id = 397,
    maxBases = 4,
    tickRate = 2,
    resourcesFromBases = {
      [0] = 0,
      [1] = 1,
      [2] = 1.5,
      [3] = 2,
      [4] = 6,
    },
    resourcesFromFlags = {
      [0] = 0,
      [1] = 75,
      [2] = 85,
      [3] = 100,
      [4] = 500,
    },
  },
}

function mod:EnterZone(id)
  NS.IS_EOTS = true
  NS.Info:StartInfoTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].tickRate, {
    baseResources = instanceIdToMapId[id].resourcesFromBases,
    flagResources = instanceIdToMapId[id].resourcesFromFlags,
  }, instanceIdToMapId[id].maxBases)
end

function mod:ExitZone()
  NS.IS_EOTS = false
  NS.Info:StopInfoTracker()
end

for id in next, instanceIdToMapId do
  NS.BGWC:RegisterZone(id, mod)
end
