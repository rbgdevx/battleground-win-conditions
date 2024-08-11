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

local function checkInfo(id, isBlitz)
  local convertedInfo = {}
  NS.CopyTable(instanceIdToMapId[id], convertedInfo)
  convertedInfo.assaultTime = isBlitz and 4 or 6
  convertedInfo.contestedTime = isBlitz and 30 or 60
  return convertedInfo
end

function DWG:EnterZone(id, isBlitz)
  if NS.db.global.maps.deepwindgorge.enabled then
    if not isBlitz or isBlitz == false then
      Info:SetAnchor(Banner.frame, 0, 0)

      BasePrediction:StartInfoTracker(checkInfo(id, isBlitz))
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
