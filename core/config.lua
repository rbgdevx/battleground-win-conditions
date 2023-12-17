local AddonName, NS = ...

local select = select
local UnitClass = UnitClass
local GetClassColor = GetClassColor
local CreateFrame = CreateFrame
local setmetatable = setmetatable

local GetAddOnMetadata = C_AddOns.GetAddOnMetadata

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

NS.dummyFrame = NS.dummyFrame or CreateFrame("Frame")
NS.barFrameMT = NS.barFrameMT or { __index = NS.dummyFrame }
NS.barPrototype = NS.barPrototype or setmetatable({}, NS.barFrameMT)
NS.barPrototype_mt = NS.barPrototype_mt or { __index = NS.barPrototype }

NS.userClass = select(2, UnitClass("player"))
NS.userClassHexColor = "|c" .. select(4, GetClassColor(NS.userClass))

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

NS.Static_Version = 806
NS.Version = GetAddOnMetadata(AddonName, "Version")
NS.FoundNewVersion = false
