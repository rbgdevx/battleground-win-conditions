local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local TBFG = Maps:NewMod()

local instanceIDtoMapID = {
  -- Gilneas
  [761] = {
    id = 275,
    maxBases = 3,
    tickRate = 1,
    assaultTime = 6,
    contestedTime = 60,
    baseResources = {
      [0] = 0,
      [1] = 1,
      [2] = 3,
      [3] = 30,
    },
  },
}

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  NS.CopyTable(instanceIDtoMapID[id], convertedInfo)
  convertedInfo.assaultTime = isBlitz and 4 or 6
  convertedInfo.contestedTime = isBlitz and 30 or 60
  convertedInfo.baseResources = {
    [0] = 0,
    [1] = isBlitz and 2 or 1,
    [2] = isBlitz and 5 or 3,
    [3] = 30,
  }
  return convertedInfo
end

function TBFG:EnterZone(id, isBlitz)
  if NS.db.global.maps.thebattleforgilneas.enabled then
    Info:SetAnchor(Banner.frame, 0, 0)

    BasePrediction:StartInfoTracker(checkInfo(id, isBlitz))
  end
end

function TBFG:ExitZone()
  if NS.db.global.maps.thebattleforgilneas.enabled then
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIDtoMapID do
  TBFG:RegisterZone(id)
end
