local _, NS = ...

local API = {}
NS.API = API

local next = next
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local IsInGuild = IsInGuild
local strsplit = strsplit
local tonumber = tonumber

local sformat = string.format

local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

local SendAddonMessage = C_ChatInfo.SendAddonMessage

function API:SendVersion()
  local channel

  if IsInRaid() then
    channel = (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT"
      or "RAID"
  elseif IsInGroup() then
    channel = (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT"
      or "PARTY"
  elseif IsInGuild() then
    channel = "GUILD"
  end

  if channel then
    SendAddonMessage(NS.ADDON_PREFIX, "Version;" .. NS.Version, channel)
  end
end

function API:CheckVersion(text)
  local textEx = { strsplit(";", text) }

  if textEx[1] == "Version" then
    if not NS.FoundNewVersion and tonumber(textEx[2]) > NS.Version then
      local message = sformat("New version released!")
      NS.write(message)
      NS.FoundNewVersion = true
    end
  end
end

function API:NewMod()
  local t = {}
  for k, v in next, API do
    t[k] = v
  end
  return t
end
