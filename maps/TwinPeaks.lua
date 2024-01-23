local _, NS = ...

local next = next

local FlagPrediction = NS.FlagPrediction
local Banner = NS.Banner
local Stacks = NS.Stacks
local Maps = NS.Maps

local TP = Maps:NewMod()

local instanceIdToMapId = {
  -- Twin Peaks
  [726] = {
    id = 206,
    maxFlags = 1,
    tickRate = 1,
  },
}

function TP:EnterZone(id)
  if NS.db.global.maps.twinpeaks.enabled then
    NS.IS_TP = true
    Stacks:SetAnchor(Banner.frame, 0, -5)
    FlagPrediction:StartInfoTracker(instanceIdToMapId[id].id)
  end
end

function TP:ExitZone()
  if NS.db.global.maps.twinpeaks.enabled then
    NS.IS_TP = false
    FlagPrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  TP:RegisterZone(id)
end
