local _, NS = ...

local next = next
local select = select
local IsInInstance = IsInInstance
local GetInstanceInfo = GetInstanceInfo

local After = C_Timer.After

---@type BGWC
local BGWC = NS.BGWC
local BGWCFrame = NS.BGWC.frame

local Interface = NS.Interface
local Version = NS.Version

local Maps = {}
NS.Maps = Maps

do
  local LOADING_SCREEN_DISABLED = false
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

  function Maps:EnableZone(instanceID, isBlitz)
    BGWCFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

    NS.IN_GAME = true
    NS.IS_BLITZ = isBlitz
    prevZone = instanceID

    Version:SendVersion()

    zoneIds[instanceID]:EnterZone(instanceID, isBlitz)
  end

  function Maps:PrepareZone()
    NS.PLAYER_FACTION = GetPlayerFactionGroup()
    LOADING_SCREEN_DISABLED = true

    local inInstance = IsInInstance()
    if inInstance then
      local instanceID = select(8, GetInstanceInfo())
      if zoneIds[instanceID] then
        local maxPlayers = select(5, GetInstanceInfo())

        if maxPlayers >= NS.DEFAULT_GROUP_SIZE then
          Maps:EnableZone(instanceID, false)
        else
          Maps:EnableZone(instanceID, true)
        end
      end
    else
      Interface:Clear()

      NS.IN_GAME = false
      NS.IS_BLITZ = false

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
  end

  function BGWC:LOADING_SCREEN_DISABLED()
    BGWCFrame:UnregisterEvent("LOADING_SCREEN_DISABLED")

    After(0, function()
      Maps:PrepareZone()
    end)
  end

  function Maps:ToggleZone()
    BGWCFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

    After(0, function()
      local inInstance = IsInInstance()
      if inInstance then
        Interface:Clear()

        After(15, function()
          if LOADING_SCREEN_DISABLED == false and NS.IN_GAME == false then
            self:PrepareZone()
          end
        end)
      else
        NS.IN_GAME = false
      end
    end)
  end
end

function Maps:NewMod()
  local t = {}
  for k, v in next, Maps do
    t[k] = v
  end
  return t
end
