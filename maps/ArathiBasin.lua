local _, NS = ...

local mod = NS.API:NewMod()

local next = next

local instanceIdToMapId = {
  -- ArathiBasin
  [2107] = {
    id = 1366,
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
  -- ArathiCompStomp
  [2177] = {
    id = 1383,
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
  -- ArathiBlizzard
  [1681] = {
    id = 837,
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
