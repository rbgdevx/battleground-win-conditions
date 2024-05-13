local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local TBFG = Maps:NewMod()

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

function TBFG:EnterZone(id)
  if NS.db.global.maps.thebattleforgilneas.enabled then
    Info:SetAnchor(Banner.frame, 0, 0)

    BasePrediction:StartInfoTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].tickRate, {
      baseResources = instanceIdToMapId[id].resourcesFromBases,
    }, instanceIdToMapId[id].maxBases)
  end
end

function TBFG:ExitZone()
  if NS.db.global.maps.thebattleforgilneas.enabled then
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  TBFG:RegisterZone(id)
end
