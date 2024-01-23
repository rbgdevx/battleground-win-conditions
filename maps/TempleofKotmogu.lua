local _, NS = ...

local next = next

local OrbPrediction = NS.OrbPrediction
local Anchor = NS.Anchor
local Buff = NS.Buff
local Maps = NS.Maps

local TOK = Maps:NewMod()

local instanceIdToMapId = {
  -- TempleofKotmogu
  -- Points for the positions:
  -- - outside main area/gates
  -- - outer ring/platform
  -- - inner area/inside arena
  -- Updates every 5 second
  -- 0 start, 3 out / 5, 4 ring / 5, 5 inner / 5
  -- kill = 10 pts
  -- x4 for 45s = 4x pts
  -- only tooltip1 has info
  -- tooltip1: "TEAM has taken the ORB"
  [998] = {
    id = 417,
    maxOrbs = 4,
    tickRate = 5,
    resourcesFromBases = {},
  },
}

function TOK:EnterZone(id)
  if NS.db.global.maps.templeofkotmogu.enabled then
    NS.IS_TEMPLE = true
    Buff:SetAnchor(Anchor.frame, 0, 0)
    OrbPrediction:StartInfoTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].maxOrbs)
  end
end

function TOK:ExitZone()
  if NS.db.global.maps.templeofkotmogu.enabled then
    NS.IS_TEMPLE = false
    OrbPrediction:StopInfoTracker()
  end
end

for id in next, instanceIdToMapId do
  TOK:RegisterZone(id)
end
