local _, NS = ...

local next = next

local FlagPrediction = NS.FlagPrediction
local Banner = NS.Banner
local Info = NS.Info
local Stacks = NS.Stacks
local Maps = NS.Maps

local WG = Maps:NewMod()

local instanceIdToMapId = {
  -- Warsong Gulch
  [2106] = {
    id = 1339,
  },
}

function WG:EnterZone(id)
  if NS.db.global.maps.warsonggulch.enabled then
    NS.IS_WG = true
    Info:SetAnchor(Banner.frame, 0, 0)

    if NS.db.global.general.info == false then
      Stacks:SetAnchor(Info.frame, 0, -5, "TOPLEFT", "TOPLEFT")
    else
      Stacks:SetAnchor(Info.frame, 0, 0, "TOPLEFT", "TOPLEFT")
    end

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
