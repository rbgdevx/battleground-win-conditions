local AddonName, NS = ...

local select = select
local UnitClass = UnitClass
local GetClassColor = GetClassColor

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata

NS.PLAYER_FACTION = GetPlayerFactionGroup()
NS.ALLIANCE_NAME = FACTION_ALLIANCE
NS.HORDE_NAME = FACTION_HORDE
NS.WIN_NOUN = "You"
NS.LOSE_NOUN = "They"
NS.ASSAULT_TIME = 5
NS.CONTESTED_TIME = 60
NS.ORB_BUFF_TIME = 45
NS.IN_GAME = false
NS.IS_TEMPLE = false
NS.IS_EOTS = false
NS.IS_SSM = false

NS.userClass = select(2, UnitClass("player"))
NS.userClassHexColor = "|c" .. select(4, GetClassColor(NS.userClass))

NS.OPTIONS_LABEL = AddonName

-------------------------------------------------------
-- Default SavedVariables
-------------------------------------------------------

NS.DEFAULT_SETTINGS = {
  version = 8,
  lock = false,
  test = true,
  banner = false,
  position = {
    "CENTER",
    "CENTER",
    0,
    0,
  },
}

NS.Static_Version = 8110
NS.Version = GetAddOnMetadata(AddonName, "Version")
NS.FoundNewVersion = false
