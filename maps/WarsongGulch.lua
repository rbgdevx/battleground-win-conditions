local _, NS = ...

local next = next

local FlagPrediction = NS.FlagPrediction
local Banner = NS.Banner
local Stacks = NS.Stacks
local Maps = NS.Maps

local WG = Maps:NewMod()

local instanceIdToMapId = {
  -- Warsong Gulch
  [2106] = {
    id = 1339,
    maxFlags = 1,
    tickRate = 1,
  },
}

function WG:EnterZone(id)
  if NS.db.global.maps.warsonggulch.enabled then
    NS.IS_WG = true
    Stacks:SetAnchor(Banner.frame, 0, -5)
    FlagPrediction:StartInfoTracker(instanceIdToMapId[id].id)
  end
end

function WG:ExitZone()
  if NS.db.global.maps.warsonggulch.enabled then
    NS.IS_WG = false
    FlagPrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  WG:RegisterZone(id)
end
