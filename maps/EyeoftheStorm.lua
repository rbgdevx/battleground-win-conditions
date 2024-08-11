local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps
local Flags = NS.Flags
local Bases = NS.Bases

local EOTS = Maps:NewMod()

local instanceIdToMapId = {
  -- EyeoftheStorm
  -- only iconState 1 has flag info
  -- "TEAM has taken the flag"
  [566] = {
    id = 112,
    maxBases = 4,
    tickRate = 2,
    assaultTime = 6,
    contestedTime = 60,
    baseResources = {
      [0] = 0,
      [1] = 1,
      [2] = 1.5,
      [3] = 2,
      [4] = 6,
    },
    flagResources = {
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
    assaultTime = 6,
    contestedTime = 60,
    baseResources = {
      [0] = 0,
      [1] = 1,
      [2] = 1.5,
      [3] = 2,
      [4] = 6,
    },
    flagResources = {
      [0] = 0,
      [1] = 75,
      [2] = 85,
      [3] = 100,
      [4] = 500,
    },
  },
}

function EOTS:EnterZone(id, isBlitz)
  if NS.db.global.maps.eyeofthestorm.enabled then
    NS.IS_EOTS = true

    if not isBlitz or isBlitz == false then
      Info:SetAnchor(Banner.frame, 0, 0)
      Flags:SetAnchor(Bases.frame, 0, -5)

      BasePrediction:StartInfoTracker(instanceIdToMapId[id])
    end
  end
end

function EOTS:ExitZone()
  if NS.db.global.maps.eyeofthestorm.enabled then
    NS.IS_EOTS = false
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  EOTS:RegisterZone(id)
end
