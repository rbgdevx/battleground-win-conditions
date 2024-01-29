local _, NS = ...

local select = select
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local UnitName = UnitName
local GetRealmName = GetRealmName

local sformat = string.format

local GetPlayerFactionGroup = GetPlayerFactionGroup

---@type BGWC
local BGWC = NS.BGWC
local BGWCFrame = NS.BGWC.frame

local Maps = NS.Maps
local Interface = NS.Interface

function BGWC:PLAYER_ENTERING_WORLD()
  Maps:ToggleZone()
end

function BGWC:PLAYER_LOGIN()
  BGWCFrame:UnregisterEvent("PLAYER_LOGIN")

  NS.PLAYER_GUID = UnitGUID("player")
  NS.PLAYER_CLASS = select(2, UnitClass("player"))
  NS.PLAYER_FACTION = GetPlayerFactionGroup()

  NS.userName = UnitName("player")
  NS.userRealm = GetRealmName()
  NS.userNameWithRealm = sformat("%s-%s", NS.userName, NS.userRealm)

  Interface:Create()

  BGWCFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end
BGWCFrame:RegisterEvent("PLAYER_LOGIN")
