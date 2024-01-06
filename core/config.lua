local AddonName, NS = ...

local select = select
local UnitClass = UnitClass
local GetClassColor = GetClassColor

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

NS.ADDON_PREFIX = "BGWC_VERSION"
NS.OPTIONS_LABEL = AddonName
NS.FoundNewVersion = false
NS.Version = 8113

-------------------------------------------------------
-- Default SavedVariables
-------------------------------------------------------

NS.DEFAULT_SETTINGS = {
  version = NS.Version,
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
