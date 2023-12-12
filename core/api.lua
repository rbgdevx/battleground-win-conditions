local _, NS = ...

local API = {}
NS.API = API

local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild

local SendAddonMessage = C_ChatInfo.SendAddonMessage
local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix

local checkTimer = nil

local function SendVersion()
  if IsInRaid() then
    SendAddonMessage(
      "BGWC_VERSION",
      "Version;" .. NS.Static_Version,
      (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "RAID"
    )
  elseif IsInGroup() then
    SendAddonMessage(
      "BGWC_VERSION",
      "Version;" .. NS.Static_Version,
      (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "PARTY"
    )
  elseif IsInGuild() then
    SendAddonMessage("BGWC_VERSION", "Version;" .. NS.Static_Version, "GUILD")
  end
end

function API:CheckVersion()
  RegisterAddonMessagePrefix("BGWC_VERSION")

  if checkTimer == nil then
    checkTimer = C_Timer.NewTimer(10, SendVersion)
  end
end

function API:NewMod()
  local t = {}
  for k, v in next, API do
    t[k] = v
  end
  return t
end
