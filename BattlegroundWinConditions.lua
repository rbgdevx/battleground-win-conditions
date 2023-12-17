local AddonName, NS = ...

local API = NS.API
local Options = NS.Options
local Interface = NS.Interface

local select = select
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local IsInInstance = IsInInstance
local CreateFrame = CreateFrame
local GetInstanceInfo = GetInstanceInfo
local UnitName = UnitName
local GetRealmName = GetRealmName
local strsplit = strsplit
local tonumber = tonumber
local print = print

local sformat = string.format

local BGWC = CreateFrame("Frame")
BGWC:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, ...)
end)

NS.BGWC = BGWC

do
  local prevZone = 0
  local zoneIds = {}

  function BGWC:RegisterZone(instanceID, mod)
    zoneIds[instanceID] = mod
  end

  function BGWC:ToggleForZone()
    local inInstance = IsInInstance()

    if inInstance then
      NS.Timer(0, function() -- Some info isn't available until 1 frame after loading is done
        local _, instanceType, _, _, maxPlayers, _, _, instanceID, _, _, _, _ = GetInstanceInfo()

        if instanceType == "pvp" and zoneIds[instanceID] and maxPlayers > 8 then
          self:Enable(instanceID)
        end
      end)
    else
      self:Disable()
    end
  end

  function BGWC:Enable(instanceID)
    self:RegisterEvent("PLAYER_LEAVING_WORLD")

    prevZone = instanceID
    Interface:ClearInterface()
    NS.PLAYER_FACTION = GetPlayerFactionGroup()
    NS.IN_GAME = true

    zoneIds[instanceID]:EnterZone(instanceID)
  end

  function BGWC:PLAYER_LEAVING_WORLD()
    self:UnregisterEvent("PLAYER_LEAVING_WORLD")

    Interface:ClearInterface()
    NS.IN_GAME = false

    zoneIds[prevZone]:ExitZone()
  end

  function BGWC:Disable()
    self:RegisterEvent("LOADING_SCREEN_DISABLED")
  end
end

function BGWC:ADDON_LOADED(addon)
  if addon == AddonName then
    self:UnregisterEvent("ADDON_LOADED")

    Options:InitDB()
    Options:InitializeOptions()
    Interface:InitializeInterface()

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CHAT_MSG_ADDON")
  end
end
BGWC:RegisterEvent("ADDON_LOADED")

function BGWC:PLAYER_LOGIN()
  self:UnregisterEvent("PLAYER_LOGIN")

  NS.PLAYER_GUID = UnitGUID("player")
  NS.PLAYER_CLASS = select(2, UnitClass("player"))
  NS.PLAYER_FACTION = GetPlayerFactionGroup()

  NS.userName = UnitName("player")
  NS.userRealm = GetRealmName()
  NS.userNameWithRealm = sformat("%s-%s", NS.userName, NS.userRealm)
end
BGWC:RegisterEvent("PLAYER_LOGIN")

function BGWC:CHAT_MSG_ADDON(prefix, version, _, sender, ...)
  if sender == NS.userNameWithRealm then
    return
  end

  if prefix == "BGWC_VERSION" then
    local messageEx = { strsplit(";", version) }
    if messageEx[1] == "Version" then
      print("NS.FoundNewVersion", NS.FoundNewVersion, tonumber(messageEx[2]), NS.Static_Version)

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
  self:UnregisterEvent("LOADING_SCREEN_DISABLED")

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
