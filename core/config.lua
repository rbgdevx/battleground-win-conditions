local _, NS = ...

local select = select
local UnitClass = UnitClass
local GetClassColor = GetClassColor
local CreateFrame = CreateFrame

---@class PositionArray
---@field[1] string
---@field[2] string
---@field[3] number
---@field[4] number

---@class ColorArray
---@field r number
---@field g number
---@field b number
---@field a number

---@class BannerTable : table
---@field bannerfont string
---@field bannerscale number
---@field tiebgcolor ColorArray
---@field tietextcolor ColorArray
---@field winbgcolor ColorArray
---@field wintextcolor ColorArray
---@field losebgcolor ColorArray
---@field losetextcolor ColorArray

---@class InfoTable : table
---@field infofont string
---@field infofontsize number

---@class GeneralTable : table
---@field version number
---@field lock boolean
---@field test boolean
---@field banner boolean
---@field bannergroup BannerTable
---@field infogroup InfoTable

---@class MapTable : table
---@field enabled boolean

---@class EOTSTable : table
---@field enabled boolean
---@field showflaginfo boolean

---@class MapsTable : table
---@field arathibasin MapTable
---@field deepwindgorge MapTable
---@field eyeofthestorm EOTSTable
---@field silvershardmines MapTable
---@field templeofkotmogu MapTable
---@field thebattleforgilneas MapTable
---@field twinpeaks MapTable
---@field warsonggulch MapTable

---@class GlobalTable : table
---@field general GeneralTable
---@field maps MapsTable
---@field position PositionArray
---@field lastFlagCapBy string

---@class DBTable : table
---@field global GlobalTable

---@class BGWC
---@field ADDON_LOADED function
---@field PLAYER_LOGIN function
---@field UPDATE_UI_WIDGET function
---@field LOADING_SCREEN_DISABLED function
---@field PLAYER_LEAVING_WORLD function
---@field PLAYER_ENTERING_WORLD function
---@field UNIT_AURA function
---@field ARENA_OPPONENT_UPDATE function
---@field CHAT_MSG_ADDON function
---@field CHAT_MSG_BG_SYSTEM_ALLIANCE function
---@field CHAT_MSG_BG_SYSTEM_HORDE function
---@field CHAT_MSG_BG_SYSTEM_NEUTRAL function
---@field SlashCommands function
---@field frame Frame
---@field db DBTable

---@type BGWC
---@diagnostic disable-next-line: missing-fields
local BGWC = {}
NS.BGWC = BGWC

local BGWCFrame = CreateFrame("Frame", "BGWCFrame")
BGWCFrame:SetScript("OnEvent", function(_, event, ...)
  if BGWC[event] then
    BGWC[event](BGWC, ...)
  end
end)
NS.BGWC.frame = BGWCFrame

NS.MAX_PLAYERS = 0
NS.PLAYER_FACTION = GetPlayerFactionGroup()
NS.ALLIANCE_NAME = FACTION_ALLIANCE
NS.HORDE_NAME = FACTION_HORDE
NS.WIN_NOUN = "You"
NS.LOSE_NOUN = "They"
NS.ASSAULT_TIME = 6
NS.CONTESTED_TIME = 60
NS.ORB_BUFF_TIME = 45
NS.STACK_TIME = 30
NS.IN_GAME = false
NS.IS_TEMPLE = false
NS.IS_EOTS = false
NS.IS_SSM = false
NS.IS_TP = false
NS.IS_WG = false

NS.userClass = select(2, UnitClass("player"))
NS.userClassHexColor = "|c" .. select(4, GetClassColor(NS.userClass))

NS.ADDON_PREFIX = "BGWC_VERSION"
NS.FoundNewVersion = false
NS.VERSION = 9316

NS.DefaultDatabase = {
  global = {
    general = {
      lock = false,
      test = true,
      banner = false,
      bannergroup = {
        bannerfont = "Friz Quadrata TT",
        bannerscale = 1,
        tiebgcolor = {
          r = 0 / 255,
          g = 0 / 255,
          b = 0 / 255,
          a = 0.9,
        },
        tietextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
        winbgcolor = {
          r = 36 / 255,
          g = 126 / 255,
          b = 36 / 255,
          a = 1,
        },
        wintextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
        losebgcolor = {
          r = 175 / 255,
          g = 34 / 255,
          b = 47 / 255,
          a = 1,
        },
        losetextcolor = {
          r = 255 / 255,
          g = 255 / 255,
          b = 255 / 255,
          a = 1,
        },
      },
      infogroup = {
        infofont = "Friz Quadrata TT",
        infofontsize = 12,
      },
    },
    maps = {
      arathibasin = {
        enabled = true,
      },
      deepwindgorge = {
        enabled = true,
      },
      eyeofthestorm = {
        enabled = true,
        showflaginfo = true,
      },
      silvershardmines = {
        enabled = false,
      },
      templeofkotmogu = {
        enabled = true,
      },
      thebattleforgilneas = {
        enabled = true,
      },
      twinpeaks = {
        enabled = true,
        showdebuffinfo = false,
      },
      warsonggulch = {
        enabled = true,
        showdebuffinfo = false,
      },
    },
    position = {
      "CENTER",
      "CENTER",
      0,
      0,
    },
    lastFlagCapBy = "",
    version = NS.VERSION,
  },
}
