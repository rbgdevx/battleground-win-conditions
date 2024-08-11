local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local DWG = Maps:NewMod()

local instanceIdToMapId = {
  -- DeepwindGorge
  [2245] = {
    id = 1576,
    maxBases = 5,
    tickRate = 2,
    assaultTime = 6,
    contestedTime = 60,
    baseResources = {
      [0] = 0,
      [1] = 1,
      [2] = 1.5,
      [3] = 2,
      [4] = 3.5,
      [5] = 30,
    },
  },
}

function DWG:EnterZone(id, isBlitz)
  if NS.db.global.maps.deepwindgorge.enabled then
    if not isBlitz or isBlitz == false then
      Info:SetAnchor(Banner.frame, 0, 0)

      BasePrediction:StartInfoTracker(instanceIdToMapId[id])
    end
  end
end

function DWG:ExitZone()
  if NS.db.global.maps.deepwindgorge.enabled then
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  DWG:RegisterZone(id)
end
