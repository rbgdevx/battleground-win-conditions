local AddonName, NS = ...

local API = NS.API
local Options = NS.Options
local Interface = NS.Interface

local CreateFrame = CreateFrame
local select = select
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local IsInInstance = IsInInstance
local GetInstanceInfo = GetInstanceInfo
local UnitName = UnitName
local GetRealmName = GetRealmName
local strsplit = strsplit
local tonumber = tonumber

local sformat = string.format

local GetPlayerFactionGroup = GetPlayerFactionGroup

local BGWC = {}
NS.BGWC = BGWC

local BGWCFrame = CreateFrame("Frame", "BGWCFrame")
BGWCFrame:SetScript("OnEvent", function(_, event, ...)
  if BGWC[event] then
    BGWC[event](BGWC, ...)
  end
end)

do
  local prevZone = 0
  local zoneIds = {}

  function BGWC:RegisterZone(instanceID, mod)
    zoneIds[instanceID] = mod
  end

  function BGWC:PLAYER_LEAVING_WORLD()
    BGWCFrame:UnregisterEvent("PLAYER_LEAVING_WORLD")

    Interface:ClearInterface()
    NS.IN_GAME = false

    zoneIds[prevZone]:ExitZone()
  end

  function BGWC:Enable(instanceID)
    BGWCFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

    prevZone = instanceID
    NS.PLAYER_FACTION = GetPlayerFactionGroup()
    NS.IN_GAME = true

    zoneIds[instanceID]:EnterZone(instanceID)
  end

  function BGWC:Disable()
    BGWCFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
  end

  function BGWC:ToggleForZone()
    local inInstance = IsInInstance()

    if inInstance then
      NS.Timer(0, function() -- Some info isn't available until 1 frame after loading is done
        local _, instanceType, _, _, maxPlayers, _, _, instanceID, _, _, _, _ = GetInstanceInfo()

        if instanceType == "pvp" then
          Interface:ClearInterface()

          if zoneIds[instanceID] and maxPlayers > 8 then
            self:Enable(instanceID)
          end
        end
      end)
    else
      self:Disable()
    end
  end
end

function BGWC:ADDON_LOADED(addon)
  if addon == AddonName then
    BGWCFrame:UnregisterEvent("ADDON_LOADED")

    Options:InitDB()
    Interface:InitializeInterface()
    Options:InitializeOptions()

    BGWCFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    BGWCFrame:RegisterEvent("CHAT_MSG_ADDON")
  end
end
BGWCFrame:RegisterEvent("ADDON_LOADED")

function BGWC:PLAYER_LOGIN()
  BGWCFrame:UnregisterEvent("PLAYER_LOGIN")

  NS.PLAYER_GUID = UnitGUID("player")
  NS.PLAYER_CLASS = select(2, UnitClass("player"))
  NS.PLAYER_FACTION = GetPlayerFactionGroup()

  NS.userName = UnitName("player")
  NS.userRealm = GetRealmName()
  NS.userNameWithRealm = sformat("%s-%s", NS.userName, NS.userRealm)
end
BGWCFrame:RegisterEvent("PLAYER_LOGIN")

function BGWC:CHAT_MSG_ADDON(prefix, version, _, sender, ...)
  if sender == NS.userNameWithRealm then
    return
  end

  if prefix == "BGWC_VERSION" then
    local messageEx = { strsplit(";", version) }
    if messageEx[1] == "Version" then
      if not NS.FoundNewVersion and tonumber(messageEx[2]) > NS.Static_Version then
        local text = sformat("New version released!")
        NS.write(text)
        NS.FoundNewVersion = true
      end
    end
  end
end

function BGWC:PLAYER_ENTERING_WORLD()
  self:ToggleForZone()
  API:CheckVersion()
end

function BGWC:LOADING_SCREEN_DISABLED()
  BGWCFrame:UnregisterEvent("LOADING_SCREEN_DISABLED")

  NS.Timer(0, function() -- Timers aren't fully functional until 1 frame after loading is done
    if NS.db.test then
      if NS.db.banner then
        Interface:CreateTestBannerInfo()
      else
        Interface:CreateTestInfo()
      end
    end
  end)
end
