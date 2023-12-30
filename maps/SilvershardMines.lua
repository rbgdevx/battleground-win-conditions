local _, NS = ...

local mod = NS.API:NewMod()

local next = next

local instanceIdToMapId = {
  -- Silvershard Mines
  [727] = {
    id = 423,
    maxCarts = 3,
    tickRate = 2,
    cartResources = {
      [0] = 0, -- 9sec -- respawn
      [1] = 90, -- 3min 0sec -- top short
      [2] = 116, -- 3min 52sec -- top long
      [3] = 64, -- 2min 8sec -- middle
      [4] = 48, -- 1min 36sec -- lava short
      [5] = 76, -- 2min 32sec -- lava long
    },
    -- Cart capping times in seconds, rounded up 1 second each
    cartTimers = {
      [0] = 10, -- 9sec -- respawn
      [1] = 181, -- 3min 0sec -- top short
      [2] = 233, -- 3min 52sec -- top long
      [3] = 129, -- 2min 8sec -- middle
      [4] = 97, -- 1min 36sec -- lava short
      [5] = 153, -- 2min 32sec -- lava long
    },
  },
}

function mod:EnterZone(id)
  NS.IS_SSM = true
  NS.Info:StartInfoTracker(instanceIdToMapId[id].id, instanceIdToMapId[id].tickRate, {
    cartResources = instanceIdToMapId[id].cartResources,
    cartTimers = instanceIdToMapId[id].cartTimers,
  }, instanceIdToMapId[id].maxCarts)
end

function mod:ExitZone()
  NS.IS_SSM = false
  NS.Info:StopInfoTracker()
end

for id in next, instanceIdToMapId do
  NS.BGWC:RegisterZone(id, mod)
end
