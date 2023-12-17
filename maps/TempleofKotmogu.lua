local _, NS = ...

local mod = NS.API:NewMod()

local next = next

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
    maxBases = 4,
    tickRate = 5,
    resourcesFromBases = {},
  },
}

function mod:EnterZone(id)
  NS.IS_TEMPLE = true
  NS.Info:StartBaseTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].maxBases)
end

function mod:ExitZone()
  NS.IS_TEMPLE = false
  NS.Info:StopBaseTracker()
end

for id in next, instanceIdToMapId do
  NS.BGWC:RegisterZone(id, mod)
end
