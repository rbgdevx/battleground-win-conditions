local _, NS = ...

local select = select
local IsInInstance = IsInInstance
local GetInstanceInfo = GetInstanceInfo
local GetNumGroupMembers = GetNumGroupMembers

local After = C_Timer.After

---@type BGWC
local BGWC = NS.BGWC
local BGWCFrame = NS.BGWC.frame

local Interface = NS.Interface
local Version = NS.Version

local Maps = {}
NS.Maps = Maps

function BGWC:LOADING_SCREEN_DISABLED()
  BGWCFrame:UnregisterEvent("LOADING_SCREEN_DISABLED")

  After(0, function()
    local inInstance = IsInInstance()
    if not inInstance or inInstance == false then
      Interface:Clear()

      NS.PLAYER_FACTION = GetPlayerFactionGroup()
      NS.IN_GAME = false

      if NS.db.global.general.test then
        if NS.db.global.general.banner then
          Interface:CreateTestBanner()
        else
          if NS.db.global.general.info then
            Interface:CreateTestInfo()
          else
            Interface:CreateTestBanner()
            Interface:CreateTestInfo()
          end
        end
      end
    end
  end)
end

do
  local prevZone = 0
  local zoneIds = {}

  function Maps:RegisterZone(instanceID)
    zoneIds[instanceID] = self
  end

  -- The "PLAYER_LEAVING_WORLD" and "PLAYER_LOGOUT" events both fire on a ui reload so addons can shut down cleanly before being reloaded
  -- https://www.reddit.com/r/wowaddons/comments/92ch0u/comment/e34zj4j/
  function BGWC:PLAYER_LEAVING_WORLD()
    BGWCFrame:UnregisterEvent("PLAYER_LEAVING_WORLD")

    local inInstance = IsInInstance()
    if not inInstance or inInstance == false then
      zoneIds[prevZone]:ExitZone()
      prevZone = 0
    end
  end

  function Maps:EnableZone(instanceID)
    BGWCFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

    NS.IN_GAME = true
    NS.PLAYER_FACTION = GetPlayerFactionGroup()
    prevZone = instanceID

    Version:SendVersion()

    zoneIds[instanceID]:EnterZone(instanceID)
  end

  function Maps:ToggleZone()
    BGWCFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

    local inInstance = IsInInstance()
    if inInstance then
      Interface:Clear()

      local instanceID = select(8, GetInstanceInfo())
      if zoneIds[instanceID] then
        After(5, function()
          local maxPlayers = select(5, GetInstanceInfo())
          local groupSize = GetNumGroupMembers()

          if maxPlayers == 0 or groupSize == 0 or maxPlayers >= 10 or groupSize > 8 then
            Maps:EnableZone(instanceID)
          end
        end)
      end
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
