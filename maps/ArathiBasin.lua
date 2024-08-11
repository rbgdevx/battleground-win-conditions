local _, NS = ...

local next = next

local BasePrediction = NS.BasePrediction
local Banner = NS.Banner
local Info = NS.Info
local Maps = NS.Maps

local AB = Maps:NewMod()

-- NS.SWAP_TIME = 15
-- NS.CONTROL_TIME = 45
-- NS.RESET_TIME = 5

local instanceIdToMapId = {
  -- ArathiBasin
  [2107] = {
    id = 1366,
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
  -- ArathiCompStomp
  [2177] = {
    id = 1383,
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
  -- ArathiBlizzard
  [1681] = {
    id = 837,
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

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  convertedInfo.assaultTime = isBlitz and 4 or 6
  convertedInfo.contestedTime = isBlitz and 30 or 60
  return convertedInfo
end

function AB:EnterZone(id, isBlitz)
  if NS.db.global.maps.arathibasin.enabled then
    if not isBlitz or isBlitz == false then
      Info:SetAnchor(Banner.frame, 0, 0)

      BasePrediction:StartInfoTracker(checkInfo(id, isBlitz))
    end
  end
end

function AB:ExitZone()
  if NS.db.global.maps.arathibasin.enabled then
    BasePrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  AB:RegisterZone(id)
end
