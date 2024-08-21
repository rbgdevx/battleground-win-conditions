local _, NS = ...

local next = next
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
      NS.PLAYER_FACTION = GetPlayerFactionGroup()
      zoneIds[prevZone]:ExitZone()
      prevZone = 0
    end
  end

  function Maps:EnableZone(instanceID, isBlitz)
    BGWCFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

    NS.PLAYER_FACTION = GetPlayerFactionGroup()
    NS.IS_BLITZ = NS.isBlitz()
    prevZone = instanceID

    Version:SendVersion()

    if NS.DEBUG then
      print("Maps:EnableZone(instanceID, isBlitz)", NS.PLAYER_FACTION, isBlitz)
    end

    zoneIds[instanceID]:EnterZone(instanceID, isBlitz)
  end

  local function checkMaxPlayers(instanceID)
    local maxPlayers = select(5, GetInstanceInfo())
    local groupSize = GetNumGroupMembers()

    if NS.DEBUG then
      print("checkMaxPlayers(instanceID)", maxPlayers, groupSize)
    end

    if maxPlayers == 0 then
      After(1, function()
        checkMaxPlayers(instanceID)
      end)
    else
      if maxPlayers >= NS.DEFAULT_GROUP_SIZE or groupSize > NS.MIN_GROUP_SIZE then
        Maps:EnableZone(instanceID, false)
      else
        Maps:EnableZone(instanceID, true)
      end
    end
  end

  function Maps:PrepareZone()
    NS.PLAYER_FACTION = GetPlayerFactionGroup()

    if NS.DEBUG then
      print("Maps:PrepareZone()", NS.PLAYER_FACTION)
    end

    Interface:Clear()

    local inInstance = IsInInstance()
    if inInstance then
      local instanceID = select(8, GetInstanceInfo())

      NS.IN_GAME = true

      if zoneIds[instanceID] then
        checkMaxPlayers(instanceID)
      end
    else
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

  -- Fired when loading screen disappears; when player is finished loading the new zone.
  -- Also fired upon death, which we don't want, so we unregister it after its first use
  -- Because of this we dont want to use this as a reliable source to start the zone code
  function BGWC:LOADING_SCREEN_DISABLED()
    BGWCFrame:UnregisterEvent("LOADING_SCREEN_DISABLED")
    NS.PLAYER_FACTION = GetPlayerFactionGroup()

    if NS.DEBUG then
      print("BGWC:LOADING_SCREEN_DISABLED()", NS.PLAYER_FACTION)
    end
  end

  function Maps:ToggleZone()
    BGWCFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

    if NS.DEBUG then
      print("Maps:ToggleZone()", NS.PLAYER_FACTION)
    end

    self:PrepareZone()
  end
end

function Maps:NewMod()
  local t = {}
  for k, v in next, Maps do
    t[k] = v
  end
  return t
end
