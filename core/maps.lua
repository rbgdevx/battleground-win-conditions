local _, NS = ...

local next = next
local select = select
local IsInInstance = IsInInstance
local GetInstanceInfo = GetInstanceInfo
local GetNumGroupMembers = GetNumGroupMembers

local After = C_Timer.After
local IsSoloRBG = C_PvP.IsSoloRBG

local Interface = NS.Interface
local Version = NS.Version

local Maps = {}
NS.Maps = Maps

do
  local prevZone = 0
  local zoneIds = {}

  function Maps:RegisterZone(instanceID)
    zoneIds[instanceID] = self
  end

  function Maps:DisableZone()
    if zoneIds[prevZone] then
      zoneIds[prevZone]:ExitZone()
      prevZone = 0
    end
  end

  function Maps:EnableZone(instanceID, isBlitz)
    NS.PLAYER_FACTION = GetPlayerFactionGroup()
    NS.IS_BLITZ = NS.isBlitz()

    prevZone = instanceID
    zoneIds[instanceID]:EnterZone(instanceID, isBlitz)

    Version:SendVersion()
  end

  local function checkMaxPlayers(instanceID)
    local function checkPlayers()
      local maxPlayers = select(5, GetInstanceInfo())
      local groupSize = GetNumGroupMembers()

      if maxPlayers == 0 then
        After(1, checkPlayers)
      else
        local isBlitz = not (maxPlayers >= NS.DEFAULT_GROUP_SIZE or groupSize > NS.MIN_GROUP_SIZE or not IsSoloRBG())

        Maps:EnableZone(instanceID, isBlitz)
      end
    end

    checkPlayers()
  end

  function Maps:PrepareZone()
    if IsInInstance() then
      NS.IN_GAME = true

      local instanceID = select(8, GetInstanceInfo())
      if zoneIds[instanceID] then
        checkMaxPlayers(instanceID)
      end
    else
      NS.IN_GAME = false
      NS.IS_BLITZ = false

      Interface:Start()
    end
  end
end

function Maps:NewMod()
  local t = {}
  for k, v in next, Maps do
    t[k] = v
  end
  return t
end
